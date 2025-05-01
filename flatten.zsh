# Flatten directory tree - `flatten` command

# Show usage/help
function Flatten_ShowHelp {
    printf "Flatten directory tree - collect all files into one target directory\n\n"
    printf "Usage:\n"
    printf "  flatten [options] source_dir [source_dir2 ...] destination_dir\n\n"
    printf "Options:\n"
    printf "  -c, --copy               Copy files instead of moving (default: move)\n"
    printf "  -o, --overwrite          Overwrite existing destination files\n"
    printf "  -N, --no-delete-empty    Do not delete empty source directories\n"
    printf "  -v, --verbose            Print each file operation\n"
    printf "  -X, --no-preserve        Do not preserve timestamps and permissions\n"
    printf "  -H, --no-create          Do not create destination directory\n"
    printf "  -e, --exclude [glob]     Exclude files matching glob (repeatable)\n"
    printf "  -s, --simulate           Dry run: show actions without modifying\n"
    printf "  -x, --extensions [.ext]  Only include files with given extensions (repeatable)\n"
    printf "  -P, --no-progress        Disable progress indicator\n"
    printf "  -M, --no-multi-source    Disable multiple source directories\n"
    printf "  -L, --follow-symlinks    Follow symlinks and copy/move targets\n"
    printf "  -h, --help               Show this help and exit\n"
}

# Main flatten logic
function flatten {

    # defaults
    local moveOn=true
    local overwriteOn=false
    local deleteEmptyOn=true
    local verboseOn=false
    local preserveOn=true
    local createOn=true
    local simulateOn=false
    local progressOn=true
    local followSymlinksOn=false
    local multiSourceOn=true
    local -a excludePatterns
    local -a extensions

    # parse options
    local optstring="coNvXHe:sx:PMLh"
    while getopts "$optstring" opt; do
        case $opt in
        c) moveOn=false ;; # -c, --copy
        o)
            overwriteOn=true
            ;;
        N) deleteEmptyOn=false ;; # -N, --no-delete-empty
        v) verboseOn=true ;;
        X) preserveOn=false ;;
        H) createOn=false ;;
        e) excludePatterns+=("$OPTARG") ;;
        s) simulateOn=true ;;
        x) extensions+=("$OPTARG") ;;
        P) progressOn=false ;;
        L) followSymlinksOn=true ;;
        M) multiSourceOn=false ;;
        h)
            Flatten_ShowHelp
            return 0
            ;;
        *)
            Flatten_ShowHelp
            return 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    # validate args
    if (($# < 2)); then
        printf "Error: need at least source and destination\n" >&2
        Flatten_ShowHelp
        return 2
    fi

    # identify sources and destination
    local -a args=("$@")
    local destinationDir=${args[-1]}
    local sources=("${args[@]:0:${#args[@]}-1}")

    # prepare destination
    [[ $createOn == true ]] && mkdir -p -- "$destinationDir"

    # build find command
    local -a findCmd=(find)
    [[ $followSymlinksOn == true ]] && findCmd+=(-L) || findCmd+=(-P)
    findCmd+=("${sources[@]}")
    for pattern in "${excludePatterns[@]}"; do
        findCmd+=(! -name "$pattern")
    done
    if ((${#extensions[@]})); then
        local -a extArgs
        for ext in "${extensions[@]}"; do
            extArgs+=(-name "*$ext" -o)
        done
        unset 'extArgs[-1]'
        findCmd+=('(' "${extArgs[@]}" ')')
    fi
    findCmd+=(-type f -print0)

    # count for progress
    local totalCount=0
    if [[ $progressOn == true ]]; then
        local -a countCmd=("${findCmd[@]/-print0/-print}")
        totalCount=$("${countCmd[@]}" | wc -l)
    fi

    # process files
    local processedCount=0
    while IFS= read -r -d '' file; do
        ((processedCount++))
        local baseName=${file:t}
        local destFile="$destinationDir/$baseName"

        # conflict handling
        if [[ -e $destFile ]]; then
            if [[ $overwriteOn == true ]]; then
                :
            else
                printf "Error: %s exists\n" "$destFile" >&2
                return 3
            fi
        fi

        # progress
        [[ $progressOn == true ]] && printf "[%d/%d] %s\n" "$processedCount" "$totalCount" "$file"

        # simulate or perform
        if [[ $simulateOn == true ]]; then
            printf "Would %s '%s' -> '%s'\n" $([[ $moveOn == true ]] && echo move || echo copy) "$file" "$destFile"
        else
            if [[ $moveOn == true ]]; then
                mv -- "$file" "$destFile"
            else
                if [[ $preserveOn == true ]]; then
                    cp -p -- "$file" "$destFile"
                else
                    cp -- "$file" "$destFile"
                fi
            fi
        fi
    done < <("${findCmd[@]}")

    # delete empty dirs
    if [[ $deleteEmptyOn == true && $moveOn == true && $simulateOn != true ]]; then
        for src in "${sources[@]}"; do
            find "$src" -type d -empty -delete
        done
    fi

    return 0
}
