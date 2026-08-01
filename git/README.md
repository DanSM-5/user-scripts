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
git log -G "<TERM>" [--branches] [--all] [--patch] [-- path/to/file]
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

## Check commit in history

### Show branches with commit in history

```bash
# All branches that contain commit
git branch --contains <hash>

# If current branch contains commit
git branch --contains <hash> | grep "$(git branch --show-current)"
```

### Detect if commit in history for scripts

```bash
if git merge-base --is-ancestor <hash> HEAD; then
  # Commit is in history
else
  # Commit is not in history
fi
```

## Show branches contained in a range

```bash
git branch --contains $(git merge-base <ref1> <ref2>) --merged <ref1> --format="%(refname:short)"
# E.g.
git branch --contains $(git merge-base HEAD master) --merged HEAD --format="%(refname:short)"

# Find common ancestor between two refs. Needed if they have started to diverge
# git merge-base <ref1> <ref2>

# Use --contains and --merged to get a range of commits, then --format to only include short branch names
# git branch --contains <ref1> --merged <ref2> --format="%(refname:short)"
```

## List all tags at a given ref

```bash
git tag --points-at <commit-hash-or-ref>
```

## Update author

### Last commit

```bash
git commit --amend --author="New Name <new@email.com>" --no-edit [--allow-empty]
git push --force-with-lease # required if already pushed
```

## Multiple commits

```bash
# Interactive mode: mark commits with 'edit' in the editor
git rebase -i HEAD~N [--force] [--root]

# Automated mode: reset author to current git config for last N commits
git rebase -i HEAD~N --exec "git commit --amend --reset-author --no-edit" [--force] [--root]

# Where N is number of commits down the history or --root from the start of the history
```

## Inital commit only

Run interactive commit to root

```bash
git rebase -i --root
```

Mark initial commit as `edit`

```
edit abc1234 Initial commit
pick def5678 Second commit
pick ghi9101 Third commit
```

Amend the commit

```bash
git commit --amend --author="New Name <new@email.com>" --no-edit [--force] [--allow-empty]
```

Continue the rebase

```bash
git rebase --continue
```

Optional: Force push if already in remote

```bash
git push --force-with-lease
```

## Diff utils

### Diff agains branch


```bash
# only list files changed
git diff --name-only $(git merge-base --fork-point <base-branch>)
```

```bash
# Full diff
git diff $(git merge-base --fork-point <base-branch>) HEAD

# Dot syntax
git diff <base-branch>...<head-branch>

# gh cli
gh pr diff
```

## Differences when using `..` and `...`

### Git log

[git log ranges](https://stackoverflow.com/questions/462974/what-are-the-differences-between-double-dot-and-triple-dot-in-git-com)

> ## Using Commit Ranges with Git Log
>
> When you're using commit ranges like `..` and `...` with git log, the difference between them is that, for branches A and B,
>
> ```bash
> git log A..B
> ```
>
> will show you all of the commits that B has that A doesn't have, while
>
> ```bash
> git log A...B
> ```
>
> will show you both the commits that A has and that B doesn't have, and the commits that B has that A doesn't have, or in other words,
> it will filter out all of the commits that both A and B share, thus only showing the commits that they don't both share.
>
> ## Visualization with Venn Diagrams & Commit Trees
>
> Here is a visual representation of `git log A..B`. The commits that branch B contains that don't exist in A is what is returned by the commit range,
> and is highlighted in red in the Venn diagram, and circled in blue in the commit tree:
>
> [git log A..B](./images/git-log-a..b-venn.png)
> [git log A..B diagram tree](./images/git-log-a..b-branch.png)
>
> These are the diagrams for `git log A...B`. Notice that the commits that are shared by both branches are not returned by the command:
>
> [git log A...B](./images/git-log-a...b-venn.png)
> [git log A...B diagram tree](./images/git-log-a...b-branch.png)
>
> ## Making the Triple-Dot Commit Range ... More Useful
>
> You can make the triple-dot commit range ... more useful in a log command by using the --left-right option to show which commits belong to which branch:
>
> ```
> $ git log --oneline --decorate --left-right --graph master...origin/master
> < 1794bee (HEAD, master) Derp some more
> > 6e6ce69 (origin/master, origin/HEAD) Add hello.txt
> ```
>
> In the above output, you'll see the commits that belong to master are prefixed with <, while commits that belong to origin/master are prefixed with >.

### Git diff

[git diff ranges](https://stackoverflow.com/questions/7251477/what-are-the-differences-between-double-dot-and-triple-dot-in-git-dif)

> *Since I'd already created these images, I thought it might be worth using them in another answer,
> although the description of the difference between `..` (dot-dot) and `...` (dot-dot-dot) is essentially
> the same as in [manojlds's answer](https://stackoverflow.com/questions/7251477/git-diff-whats-the-difference-between-having-and-no-dots/7252067#7252067).*
>
> The command `git diff` typically¹ only shows you the difference between the states of the tree between exactly two points in the commit graph.
> The `..` and `...` notations in git diff have the following meanings:
>
> ```bash
> # Left side in the illustration below:
> git diff foo..bar
> git diff foo bar  # same thing as above
>
> # Right side in the illustration below:
> git diff foo...bar
> git diff $(git merge-base foo bar) bar  # same thing as above
>```
>
> [git diff diagram](./images/git-diff-a...b.png)
>
> In other words, `git diff foo..bar` is exactly the same as `git diff foo bar`;
> both will show you the difference between the tips of the two branches foo and bar.
> On the other hand, `git diff foo...bar` will show you the difference between the "**merge base**" of the two branches and the tip of bar.
> The "**merge base**" is usually the last commit in common between those two branches,
> so this command will show you the changes that your work on bar has introduced,
> while ignoring everything that has been done on foo in the mean time.
>
> That's all you need to know about the `..` and `...` notations in git diff. However...
>
> ---
>
> ... a common source of confusion here is that `..` and `...` mean subtly different things when used in a command such as `git log`
> that expects a set of commits as one or more arguments.
> (These commands all end up using `git rev-list` to parse a list of commits from their arguments.)
>
> The meaning of `..` and `...` for `git log` can be shown graphically as below:
>
> [git rev-list](./images/git-rev-list-foo..bar.png)
>
> So, `git rev-list foo..bar` shows you everything on branch `bar` that isn't also on branch `foo`.
> On the other hand, `git rev-list foo...bar` shows you all the commits that are in either `foo` or `bar`, but *not both*.
> The third diagram just shows that if you list the two branches, you get the commits that are in either one or both of them.
>
> Well, I find that all a bit confusing, anyway, and I think the commit graph diagrams help :)
>
> ¹ I only say "typically" since when resolving merge conflicts, for example, git diff will show you a three-way merge.

## Bonus diagram

[git bonus](./images/git-bonus.png)
