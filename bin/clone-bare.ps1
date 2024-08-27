#!/usr/bin/env powershell

# clone the repo
git clone --bare @args

# return if repo was not created
if (!$?) { exit $? }

$dirrepo = if ($args[1]) { $args[1] } else {
  [System.IO.Path]::GetFileNameWithoutExtension($args[0])
}

# Setup the bare repository
Push-Location $dirrepo
# Add git remote config
# Ref: https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
Pop-Location

