# flatten-zsh

`flatten-zsh` provides a Zsh function to flatten nested directory trees into a single target directory, streamlining file consolidation. It eliminates the need for manual copying or moving of files from deeply nested hierarchies by automatically collecting all files into one location with a single command.

## Table of Contents

- [Key Features](#key-features)
- [Installation](#installation)
- [Usage Guide](#usage-guide)
- [Options](#options)
- [Configuration Details](#configuration-details)
- [Contributing](#contributing)
- [License](#license)

## Key Features

- **Flatten Nested Trees:** Recursively collect files from nested source directories into one destination.
- **Copy or Move Modes:** Copy files by default or move them with `--move`.
- **Metadata Preservation:** Retain original timestamps and permissions.
- **Pattern-Based Exclusion:** Exclude files matching glob patterns.
- **Extension Filtering:** Include only specified file extensions.
- **Dry-Run Simulation:** Preview actions without making changes.
- **Progress Reporting:** Display a progress bar during operations.
- **Automatic Cleanup:** Optionally remove empty source directories after move.

## Installation

1. **Clone the Repository (or Download `flatten.zsh`)**
    Choose a location for the script (e.g., `~/.config/zsh/plugins/flatten-zsh`).

    ```bash
    # Option 1: Clone the repository
    git clone https://github.com/kgruiz/flatten-zsh.git ~/.config/zsh/plugins/flatten-zsh

    # Option 2: Create the directory and download the file
    mkdir -p ~/.config/zsh/plugins/flatten-zsh
    curl -o ~/.config/zsh/plugins/flatten-zsh/flatten.zsh \
      https://raw.githubusercontent.com/kgruiz/flatten-zsh/main/flatten.zsh
    ```

2. **Source the Script in `.zshrc`**
    Add the following snippet to your `~/.zshrc`. Adjust `FLATTEN_FUNC_PATH` to where you placed `flatten.zsh`.

    ```bash
    # init zsh completion
    autoload -Uz compinit
    compinit

    # load flatten-zsh
    FLATTEN_FUNC_PATH="$HOME/.config/zsh/plugins/flatten-zsh/flatten.zsh"
    if [ -f "$FLATTEN_FUNC_PATH" ]; then
      if ! . "$FLATTEN_FUNC_PATH" 2>&1; then
        echo "Error: Failed to source \"$(basename "$FLATTEN_FUNC_PATH")\"" >&2
      fi
    else
      echo "Error: \"$(basename "$FLATTEN_FUNC_PATH")\" not found at:" >&2
      echo "  $FLATTEN_FUNC_PATH" >&2
    fi
    unset FLATTEN_FUNC_PATH
    ```

3. **Apply Changes**

    ```bash
    source ~/.zshrc
    ```

## Usage Guide

The `flatten` function consolidates files from one or more source directories into a single destination.

**1. Basic Flatten (Copy)**

```bash
❯ flatten src-dir dest-dir
```

**2. Move Mode**

```bash
❯ flatten --move src-dir dest-dir
```

**3. Exclude & Filter**

```bash
❯ flatten --exclude '*.tmp' --extensions .txt --extensions .md src1 src2 dest
```

**4. Dry Run & Progress**

```bash
❯ flatten --simulate --verbose --progress src-dir dest-dir
```

**5. Empty Directory Cleanup**

```bash
❯ flatten --move --delete-empty src-dir dest-dir
```

## Options

| Option                     | Short | Description                                          |
|----------------------------|-------|------------------------------------------------------|
| `--move <s> <d>`           | `-m`  | Move files instead of copying.                       |
| `--overwrite`              | `-o`  | Overwrite existing files in destination.             |
| `--no-clobber`             | `-n`  | Skip files that already exist in destination.        |
| `--delete-empty`           | `-d`  | Delete empty source directories after move.          |
| `--preserve`               | `-p`  | Preserve file timestamps and permissions.            |
| `--create`                 | `-c`  | Create destination directory if it doesn’t exist.    |
| `--exclude <pattern>`      | `-e`  | Exclude files matching glob pattern (repeatable).    |
| `--extensions <ext>`       | `-x`  | Include only specified file extensions (repeatable). |
| `--simulate`               | `-s`  | Show what would be done without making changes.      |
| `--progress`               | `-P`  | Display a progress bar during operations.            |
| `--help`                   | `-h`  | Show help message and usage.                         |

## Configuration Details

- Uses standard UNIX tools: `find`, `cp`/`mv`, `printf`.
- Defaults: copy mode; skip existing; preserve metadata; auto-create destination.
- Repeatable flags (`--exclude`, `--extensions`) accept multiple values.
- Behavior adjustable via command-line flags.

## Contributing

Contributions, bug reports, and feature suggestions are welcome. Please refer to the repository’s [issues tracker](https://github.com/kgruiz/flatten-zsh/issues) for ongoing development and discussion.

## License

Distributed under the **GNU GPL v3.0**.
See [LICENSE](LICENSE) or <https://www.gnu.org/licenses/gpl-3.0.html> for details.
