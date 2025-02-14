Git notes
===========

## List revisions

List all the revisions in the git repo (all hashes)

```bash
git rev-list --all
```

## Count number of revisions

Get the number of revisions that git is tracking on a specific revision

```bash
git rev-list --count [branch | hash | tag | tree like]
```

## Detect bare repository

Worktree will return the path to it when calling

```bash
git rev-parse --show-toplevel
```

and it will return an error if in a bare repository.

Alternatively using

```bash
git rev-parse --is-bare-repository
```

will return `true` or `false` if in a working tree or a bare repository.

## Change last commit

Remove last commit, keep changes:

```bash
git reset --soft HEAD~1
```

Remove last commit, discard changes:

```bash
git reset --hard HEAD~1
```

## Duplicate branch

Set a branch to be identical to other branch (or commits):

```bash
git reset --hard [branch | hash | tag | tree like]
```

## See changes in the repository

Use `reflog` to list the changes in the repository including reference to commits that no longer exists.
Good when a `rebase` goes wrong...

```bash
git reflog
```

## See commit patch

Print the commit patch from a commit or tree like object:

```bash
git show [hash | branch | tag | tree like]
```

## Grep in commit messages

Search for `<TERM>` in the commit messages:

```bash
git log --grep "<TERM>"
```

## Grep in patches

Search a `<TERM>` in the commit history and display the commits that contain patches that matches the `<TERM>`

- `--all`: Search in all branches
- `--patch`: Show patch included in the commit
- `-G`: Use regex for `<TERM>`
- `-S`: Use a literal string for `<TERM>`
- `--`: Start listing paths to reduce search

```bash
git log -G "<TERM>" --branches [--all] [--patch] [-- path/to/file]
```

## Show paths tracked by git (pathspec)

List files that git is tracking. Use a `'*'` to glob pathspecs such as `'*.sh'`.

```bash
git ls-files
```

## Use absolute paths

Use `:/` to prefix a pathspec to indicate use the repository as the path.

## Negate pathspec matches

Use `:!` to negate the pathspec match if using globs.

## Find the bug 🐞

The command `git bisect` performs a binary search using two commits as reference, a good commit (starting point) and a bad commit (ending point).

Start a bisect session:

```bash
git bisect start
```

Set the reference commits. Hashes are optional if you checkout to that commit:

```bash
# Set good commit
git bisect good [hash]

# Set bad commit
git bisect bad [hash]
```

Git will change between commits in the given range. Tell git about the current commit to narrow search:

```bash
git bisect [good | bad]
```

Keep going until finding the buggy commit. Then end the bisect session with:

```bash
git bisect reset
```

## Automate git bisect

Use `run` option with a command that returns `0` for a good commit, `125` for a commit to be ignored and anything between `1-127` inclusive (except of course 125) for a bad commit to automatically find the commit.

```bash
git bisect start
git bisect good [hash]
git bisect bad [hash]

git bisect run [command]
```

NOTE: The `command` can contain flags, options and multiple arguments.

## Use git to compare files side by side

Use the syntax `git diff [branch:]tracked/file another/file`. Other variations can be used.

Example:

```bash
git diff \
  master:app/assets/javascripts/audience/dashboard_bulk.js \
  tmp/dashboard_bulk.js
```

To view diff of files outside a repository use `--no-index` flag

```bash
git diff --no-index file1 file2
```

## Using submodules

Guide how to use [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

CLI [documentation](https://git-scm.com/docs/git-submodule)

### Add submodule

```bash
git submodule add [url] [[path]]
```

```bash
git submodule add git@github.com:DanSM-5/user-scripts ~/user-scripts
```

### Clone with submodules

```bash
git clone --recurse-submodules [url]
```

or

````bash
git clone [url]
cd path/to/repo
git submodule init
git submodule update
````

or

````bash
git clone [url]
cd path/to/repo
# Foolproof
git submodule update --init [--recursive] # use recursive to handle nested submodules
````

## Use git for colorising output

Get color escape sequences using git

```bash
rbb=`git config --get-color "" "red black bold"`
reset=`git config --get-color "" "reset"`

echo "${rbb}ERROR${reset}: Message"
```

## Manage config files with git

Use git to manage config files

```bash
config_location='/path/to/config'

cget () {
  git config --file "$config_location" get "$1"
}

cset () {
  git config --file "$config_location" set "$@"
}

cuns () {
  git config --file "$config_location" unset "$1"
}
```

## Show file at revision

**NOTE** The pathspec must use `/` as path separator even on windows.

```bash
git show <commit-ref>:<pathspec>
```

## Show patch on file

```bash
git show <commit-ref> [--follow] -- <pathspec>
```

**NOTE**: Add follow to track changes like renames or changes in paths.

## Tags

### List tags

```bash
git tag
```

### Add tag

```bash
# Simple tag
git tag <name>
# Anotated tag
git tag <name> -a -m <message>
# Signed tag
git tag <name> -s -m <message>
```

### Delete tag

```bash
# Local tag
git tag --delete <name>

# Remote tag
git push --delete origin <name>
```

