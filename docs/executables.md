# Command Index

## Clipboard

| Command | Description |
|---------|-------------|
| `aicopy` | FZF-based multi-file clipboard utility. Copies file content (`ctrl-e`), relative path (`ctrl-r`), or absolute path (`ctrl-t`). |
| `clip-copy` | Cross-platform clipboard write. Supports Windows, macOS, Linux (Wayland/X11), WSL, and Termux. |
| `clip-paste` | Cross-platform clipboard read. Mirrors `clip-copy`. |
| `copy-file` | Copy file *objects* (not content) to clipboard for pasting in a file manager. |
| `copy-osc52` | Copy text to clipboard via OSC52 escape sequences — works over SSH and inside terminal multiplexers. |
| `fs-copy` | Write text to `~/.cache/fs-clipboard/clipboard` — a clipboard that requires no display server. |
| `fs-paste` | Read from the filesystem clipboard written by `fs-copy`. |
| `paste-file` | Read file objects from clipboard and write them to disk. |
| `paste-osc52` | Companion to `copy-osc52`; reads OSC52 clipboard content. |

## Editor & Text

| Command | Description |
|---------|-------------|
| `comment` | Add comment markers to lines. Dispatches to a compiled binary with a bash fallback. |
| `fed` | **F**uzzy **Ed**itor — select and open files by combining fzf with ripgrep. |
| `ffd` | **F**uzzy **F**ile fin**d**er — dual-mode file finder (`ctrl-r` for fd, `ctrl-f` for fzf filter) with live preview. |
| `rfv` | **R**ipgrep **F**zf **V**im — interactive ripgrep launcher with fzf frontend. Toggle between ripgrep (`ctrl-r`) and fzf filter (`ctrl-f`). Opens a single file or multiple via the quickfix list. |
| `soe` | **S**tream **O**pen **E**ditor — reads stdin into a temp file, opens it in `$PREFERRED_EDITOR`, and writes the result back to stdout. Useful in pipelines. |
| `uncomment` | Remove comment markers from lines. Dispatches to a compiled binary with a bash fallback. |

## Notes

| Command | Description |
|---------|-------------|
| `ftxt` | Interactive browser and editor for text files in `$TXT_LOCATION` (default `$HOME/prj/txt`). Uses fzf with ripgrep search. |
| `notesdown` | Download and decrypt notes: fetches a `tar.gz.age` archive via rclone and decrypts with age. |
| `notesup` | Encrypt and upload notes: archives the notes directory, encrypts with age, and uploads via rclone. |
| `ntmp` | Open a disposable scratch buffer in `$PREFERRED_EDITOR`. Auto-generates a filename with a UUID or timestamp. |
| `ntxt` | Create a timestamped text note in `$TXT_LOCATION` and open it in the editor. |

## Git

| Command | Description |
|---------|-------------|
| `ced` | **C**uickfix **Ed**it — opens (n)vim with the quickfix list populated by `git jump diff` (all diff hunks in the repository). |
| `git-branches-between` | List branches that contain commits between two refs. |
| `git-clone-bare` | Clone a repository as a bare repo and configure it for worktree use with proper remote tracking. |
| `git-compare-files` | Browse files changed between the current branch and a target branch; preview diffs, edit files, or copy paths. |
| `git-file-history` | Show commit history for a specific file with patch preview; supports copying hashes and editing commits. |
| `git-gh-get` | Download a file or directory from GitHub without cloning the full repository. Accepts `user/repo/path` or a URL. |
| `git-jump` | Git extension that populates the editor's quickfix list with interesting locations (diffs, merge conflicts, grep results, whitespace errors). |
| `git-prev` | Show the diff of the previous commit, N commits back, or a range between commits. |
| `git-search-commits` | Interactive commit search across log messages or patch content, with delta-colored preview. |
| `git-stack` | Show commits reachable from HEAD but not yet in the target branch (your local commit stack). |
| `git-unpushed` | Show unpushed commits on the current branch versus its remote. |
| `git-unstage` | Unstage specific lines from the git index by new-file line number ranges (`N`, `N-M`, `-N`, `N-`). |

## Fuzzy Finders & Search

| Command | Description |
|---------|-------------|
| `cheat` | Interactive cheat sheet viewer backed by cheat.sh. Downloads and caches documentation; fzf frontend for searching. |
| `emoji` | Interactive emoji picker with fzf. Select to copy the emoji, its description, or both. |
| `fds` | Wrapper around `fd` that applies exclude patterns and options from local config files. |
| `fra` | Search *inside* archives using ripgrep-all (`rga`) with a fzf preview and delta-colored diff display. |
| `ghf` | GitHub PR browser: filter, preview, checkout, or open PRs in the browser using the `gh` CLI. |
| `gprj` | Project browser — list configured projects with fzf, then switch to one, open a file inside it, or copy its path. |
| `mn` | Open man pages in (n)vim. Without arguments, lists all available man pages with fzf for selection. |

## Path & System

| Command | Description |
|---------|-------------|
| `convert_path_to_unix` | Convert a Windows path to a Unix path using `cygpath` (Git Bash) or `wslpath` (WSL). |
| `convert_path_to_windows` | Convert a Unix path to a Windows path using `cygpath` or `wslpath`. |
| `detection` | Export platform and shell detection variables: `IS_WSL`, `IS_WINDOWS`, `IS_LINUX`, `IS_MAC`, `IS_BASH`, `IS_ZSH`, etc. |
| `monitor-off` | Turn off the monitor on Windows (PowerShell only). Pass `-Lock` to also lock the workstation. |
| `path_end` | Empty script. Place `bin/` last in `$PATH` and run this to verify it is reachable. |
| `start` | Cross-platform file, application, and URL opener. Delegates to `xdg-open`, `open`, `Start-Process`, or `termux-open-url` depending on the platform. |

## Projects

| Command | Description |
|---------|-------------|
| `dadd` | Add the current directory to the project directories list. |
| `ladd` | Add the current location to the project locations list. |

## Shell

| Command | Description |
|---------|-------------|
| `$` | Shell dispatcher — detect the current shell (zsh/bash/sh) and run a command in an isolated subshell with a clean prompt. |
| `dolar_bash` | Run a command in an isolated bash context with a clean prompt. Internal helper used by `$`. |
| `dolar_sh` | Run a command in an isolated sh context. Internal helper used by `$`. |
| `dolar_zsh` | Run a command in an isolated zsh context. Internal helper used by `$`. |
| `zshgencomp` | Generate a zsh completion function by parsing a command's getopt-style `--help` output. |

## Security & Auth

| Command | Description |
|---------|-------------|
| `jwt-payload` | Decode and print the payload section of a JWT token (the second dot-separated segment). |
| `oex` | **O**nepassword **Ex**ecute — inject 1Password secrets via `op inject` and run a command. WSL-friendly alternative to `op run`. |

## Utilities

| Command | Description |
|---------|-------------|
| `chadsay` | Display a randomly chosen ASCII art "Chad" figure with a speech bubble around the provided text. |
| `fromhex` | Convert a hex color (`#ABC` or `#AABBCC`) to the nearest xterm 256-color terminal index. |

## lf Utilities

All `lf_*` scripts are helper utilities for the [`lf`](https://github.com/gokcehan/lf) terminal file manager. They are intended to be called from lf mappings and commands, not directly from the shell.

- **Navigation**: `lf_fzf_jump`, `lf_fzf_jump_deep`, `lf_move_parent` — jump to a directory with fzf (shallow or deep), or navigate up to the parent while staying in `dironly` mode.
- **Search**: `lf_fzf_search` — ripgrep+fzf file search integrated with lf.
- **Git**: `lf_git_checkout`, `lf_git_log`, `lf_git_status` — fzf branch switcher, interactive log viewer with delta preview, and git status display.
- **npm**: `lf_fzf_npm_run`, `lf_npm_run` — browse and run npm scripts from the nearest `package.json`.
- **File operations**: `lf_mkdir`, `lf_touch`, `lf_open`, `lf_vim` — create directories or files (and select the result in lf), open items with the system default, or open in the preferred editor.
- **Preview & pager**: `lf_preview`, `lf_pager` — preview handler and pager (bat-backed) for lf's preview panel.
- **Config & shell**: `lf_edit_conf`, `lf_reload_conf`, `lf_lfrc`, `lf_set_shell`, `lf_starship`, `lf_starship_oncd` — edit or reload lf config, apply platform-specific settings, set the shell variable, and integrate the Starship prompt on directory change.
- **Cleanup**: `lf_cleaner` — post-processing cleanup hook called by lf after file operations.
