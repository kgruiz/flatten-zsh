# Flatten directory tree – `flatten` command

# Show usage/help
function ShowHelp {
    printf "Flatten directory tree - collect all files into one target directory\n\n"
    printf "Usage:\n"
    printf "  flatten [options] source_dir [source_dir2 ...] destination_dir\n\n"
    printf "Options:\n"
    printf "  -m, --move               Move files instead of copying (default: copy)\n"
    printf "  -o, --overwrite          Overwrite existing destination files\n"
    printf "  -n, --no-clobber         Skip if destination file exists (default: on)\n"
    printf "  -d, --delete-empty       Delete empty source directories after move (default: on)\n"
    printf "  -v, --verbose            Print each file operation\n"
    printf "  -p, --preserve           Preserve timestamps and permissions (default: on)\n"
    printf "  -c, --create             Create destination directory if missing (default: on)\n"
    printf "  -e, --exclude [glob]     Exclude files matching glob (repeatable)\n"
    printf "  -s, --simulate           Dry run: show actions without modifying\n"
    printf "  -x, --extensions [.ext]  Only include files with given extensions (repeatable)\n"
    printf "  -P, --progress           Show progress indicator (default: on)\n"
    printf "  -L, --follow-symlinks    Follow symlinks and copy/move targets\n"
    printf "  -M, --multi-source       Allow multiple source directories (default: on)\n"
    printf "  -h, --help               Show this help and exit\n"
}

# Main flatten logic
function flatten {
    # defaults
    local moveOn=false
    local overwriteOn=false
    local noClobberOn=true
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
    local optstring="mondvpce:sx:PLMh"
    while getopts "$optstring" opt; do
        case $opt in
        m) moveOn=true ;;
        o)
            overwriteOn=true
            noClobberOn=false
            ;;
        n)
            noClobberOn=true
            overwriteOn=false
            ;;
        d) deleteEmptyOn=true ;;
        v) verboseOn=true ;;
        p) preserveOn=true ;;
        c) createOn=true ;;
        e) excludePatterns+=("$OPTARG") ;;
        s) simulateOn=true ;;
        x) extensions+=("$OPTARG") ;;
        P) progressOn=true ;;
        L) followSymlinksOn=true ;;
        M) multiSourceOn=true ;;
        h | *)
            ShowHelp
            return 2
            ;;
        esac
    done
    shift $((OPTIND - 1))

    # validate args
    if (($# < 2)); then
        printf "Error: need at least source and destination\n" >&2
        ShowHelp
        return 2
    fi

    # identify sources and destination
    local -a args=("$@")
    local destinationDir=${args[-1]}
    local sources=("${args[@]:0:$#-1}")

    # prepare destination
    ((createOn)) && mkdir -p -- "$destinationDir"

    # build find command
    local -a findCmd=(find)
    ((followSymlinksOn)) && findCmd+=(-L) || findCmd+=(-P)
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
    if ((progressOn)); then
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
            if ((overwriteOn)); then
                :
            elif ((noClobberOn)); then
                ((verboseOn)) && printf "Skipping existing %s\n" "$destFile"
                continue
            else
                printf "Error: %s exists\n" "$destFile" >&2
                return 3
            fi
        fi

        # progress
        ((progressOn)) && printf "[%d/%d] %s\n" "$processedCount" "$totalCount" "$file"

        # simulate or perform
        if ((simulateOn)); then
            printf "Would %s '%s' -> '%s'\n" $([[ moveOn ]] && echo move || echo copy) "$file" "$destFile"
        else
            if ((moveOn)); then
                mv -- "$file" "$destFile"
            else
                if ((preserveOn)); then
                    cp -p -- "$file" "$destFile"
                else
                    cp -- "$file" "$destFile"
                fi
            fi
        fi
    done < <("${findCmd[@]}")

    # delete empty dirs
    if ((deleteEmptyOn && moveOn && !simulateOn)); then
        for src in "${sources[@]}"; do
            find "$src" -type d -empty -delete
        done
    fi

    return 0
}

# git@github.com:kgruiz/flatten-zsh.git
