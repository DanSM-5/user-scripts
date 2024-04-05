#!/usr/bin/env pwsh

# Legacy implementation of fzf-git.psm1 module for powershell
# This implementation relies on creating shell commands and run them
# using bash from git for windows.
# This is archived as an example to make such a hack work.

$fzf_down = ' SHELL="/bin/bash" fzf --height 50% --min-height 20 --layout=reverse --border --bind "ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down,ctrl-s:toggle-sort" '
# $fzf_down = ' SHELL="/bin/bash" fzf --height 50% --min-height 20 --layout=reverse --border --bind \"ctrl-/:change-preview-window(down|hidden|),alt-up:preview-page-up,alt-down:preview-page-down\" '

      # --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always && bat --color=always {-1})' |
$fgf_command = @'
    git -c color.status=always status --short |
'@ + $script:fzf_down + @'
    -m --ansi --nth 2..,.. \
      --preview 'if \[ -f {-1} \]; then git diff --color=always -- {-1}
'@ + "$script:__pager_command__" + @'
    | sed 1,4d | bat -p --color=always; bat --color=always {-1}; else ls -AF --color=always {-1}; fi' |
    cut -c4- | sed 's/.* -> //'
'@

$fgb_command = @'
    git branch -a --color=always | grep -v '/HEAD\s' | sort |
'@ + $script:fzf_down + @'
      --ansi --multi --tac \
        --preview 'git log --oneline --graph --date=short --color=always --pretty=\"format:%C(auto)%cd %h%d %s\" $(sed s/^..// <<< {} | cut -d\" \" -f1)' |
      sed 's/^..//' | cut -d' ' -f1 |
      sed 's#^remotes##'
'@

$fgt_command = @'
  git tag --sort -version:refname |
'@ + $script:fzf_down + @'
  --multi --preview-window right:70% \
    --preview 'git show --color=always {}
'@ + "$script:__pager_command__" + @'
  | bat --color=always'
'@

# NOTE: Investigate why grep command args where escaped
# --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always
$fgh_command = @'
  git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
'@ + $script:fzf_down + @'
  --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always
'@ + "$script:__pager_command__" + @'
    | bat -p --color=always' |
  grep -o '[a-f0-9]\{7,\}'
'@

# --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always
$fgha_command = @'
  git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
'@ + $script:fzf_down + @'
  --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always
'@ + "$script:__pager_command__" + @'
    | bat -p --color=always' |
  grep -o '[a-f0-9]\{7,\}'
'@

$fgr_command = @'
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
'@ + $script:fzf_down + @'
  --tac \
    --preview 'git log --oneline --graph --date=short --pretty=\"format:%C(auto)%cd %h%d %s\" {1}' |
  cut -d$'\t' -f1
'@

$fgs_command = @'
  git stash list |
'@ + $script:fzf_down + @'
  --reverse -d: --preview 'git show --color=always {1}
'@ + "$script:__pager_command__" + @'
  | bat -p --color=always' |
  cut -d: -f1
'@

function fgf () {
  if ($script:is_in_git_repo) { return }
  # & "$script:__gitbash__" --norc -ilc $script:fgf_command
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgf_command"
  # & "$script:__gitbash__" -c @'
  #   git -c color.status=always status --short |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview -m --ansi --nth 2..,.. \
  #     --preview '(git diff --color=always -- {-1} | sed 1,4d | bat -p --color=always; bat --color=always {-1})' |
  #   cut -c4- | sed 's/.* -> //'
# '@
}


function fgb () {
  if ($script:is_in_git_repo) { return }

  $output_file = New-TemporaryFile

  # Use Start-Process to execute the command
  $proc = Start-Process -FilePath "$script:__gitenv__" -ArgumentList @(
    $script:GITBASH_ENVIRONMENT
    "SHELL=/usr/bin/bash"
    "/usr/bin/bash"
    "-c"
    "`"source `$user_conf_path/utils/fzf-git.sh && PATH=\`"/mingw64/bin:/usr/local/bin:/usr/bin:/bin:`$PATH\`" fgb`""
  ) -NoNewWindow -PassThru -RedirectStandardOutput $output_file

  # Wait for process exit
  $proc.WaitForExit()

  # Clean process reference
  $proc = $null

  try {
    return Get-Content $output_file.FullName
  } finally {
    Remove-Item -Force $output_file.FullName
  }

  # requires -l flag for sub-shell process
  # & "$script:__gitbash__" --norc -ilc $script:fgb_command
  #
  # NOTE: Stopped working on parsing fgb_command
  # & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgb_command"

  # require to escape the string twice in pwsh and once in gitbash
  # iex $("& `"$__gitbash__`" -ilc `"git branch -a --color=always | grep -v '/HEAD\s' | sort | fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --multi --tac --preview 'git log --oneline --graph --date=short --color=always --pretty=\```"format:%C(auto)%cd %h%d %s\```" ```$(sed s/^..// <<< {} | cut -d\```" \```" -f1)' | sed 's/^..//' | cut -d' ' -f1 | sed 's#^remotes##'`"")

  # only one escape for pwsh and one for gitbash
  # & "$testbash" -ilc "git branch -a --color=always | grep -v '/HEAD\s' | sort | fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --multi --tac --preview 'git log --oneline --graph --date=short --color=always --pretty=\`"format:%C(auto)%cd %h%d %s\`" `$(sed s/^..// <<< {} | cut -d\`" \`" -f1)' | sed 's/^..//' | cut -d' ' -f1 | sed 's#^remotes##'"

  # Final version
  # & "$script:__gitbash__" -ilc @'
  #   git branch -a --color=always | grep -v '/HEAD\s' | sort |
  #     fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --multi --tac \
  #       --preview 'git log --oneline --graph --date=short --color=always --pretty=\"format:%C(auto)%cd %h%d %s\" $(sed s/^..// <<< {} | cut -d\" \" -f1)' |
  #     sed 's/^..//' | cut -d' ' -f1 |
  #     sed 's#^remotes##'
# '@
}


function fgt () {
  if ($script:is_in_git_repo) { return }
  # & "$script:__gitbash__" --norc -ilc $script:fgt_command
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgt_command"
  # & "$script:__gitbash__" -c @'
  # git tag --sort -version:refname |
  # fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --multi --preview-window right:70% \
  #   --preview 'git show --color=always {} | bat --color=always'
# '@
}

function fgh () {
  if ($script:is_in_git_repo) { return }
  # & "$script:__gitbash__" --norc -ilc $script:fgh_command
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgh_command"
  # & "$script:__gitbash__" -ilc @'
  #   git log --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
  #     --header 'Press CTRL-S to toggle sort' \
  #     --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always | bat -p --color=always' |
  #   grep -o '[a-f0-9]\{7,\}'
# '@
}

function fgha () {
  if ($script:is_in_git_repo) { return }
  # & "$script:__gitbash__" --norc -ilc $script:fgha_command
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgha_command"
  # & "$script:__gitbash__" -ilc @'
  #   git log --all --date=short --format='%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)' --graph --color=always |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
  #     --header 'Press CTRL-S to toggle sort' \
  #     --preview 'grep -o \"[a-f0-9]\{7,\}\" <<< {} | xargs git show --color=always | bat -p --color=always' |
  #   grep -o '[a-f0-9]\{7,\}'
# '@
}

function fgr () {
  if ($script:is_in_git_repo) { return }
  # & "$script:__gitbash__" --norc -ilc $script:fgr_command
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgr_command"
  # & "$script:__gitbash__" -c @'
  #   git remote -v | awk '{print $1 \"\t\" $2}' | uniq |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview --tac \
  #     --preview 'git log --oneline --graph --date=short --pretty=\"format:%C(auto)%cd %h%d %s\" {1}' |
  #   cut -d$'\t' -f1
# '@
}

function fgss () {
  if ($script:is_in_git_repo) { return }
  # & "$script:__gitbash__" --norc -ilc $script:fgs_command
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fgs_command"
  # & "$script:__gitbash__" -c @'
  #   git stash list |
  #   fzf --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview \
  #     --reverse -d: --preview 'git show --color=always {1} | bat -p --color=always' |
  #   cut -d: -f1
# '@
}

# fshow - git commit browser (enter for show, ctrl-d for diff, ` toggles sort)
$fshow_pager = if (Test-Command delta) { 'delta --paging=always' } else { 'less -R' }
$fshow_command = @'
  func () {
  local out shas sha q k
  while out=$(
      git log --graph --color=always \
          --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
      fzf --ansi --multi --no-sort --reverse --query="$q" \
          --print-query --expect=ctrl-d --bind=ctrl-s:toggle-sort); do
    q=$(head -1 <<< "$out")
    k=$(head -2 <<< "$out" | tail -1)
    shas=$(sed '1,2d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}')
    [ -z "$shas" ] && continue
    if [ "$k" = ctrl-d ]; then
      git diff --color=always $shas |
'@ + $script:fshow_pager + @'
    ; else
      for sha in $shas; do
        git show --color=always $sha |
'@ + $script:fshow_pager + @'
    ; done
    fi
  done
  }; func
'@

function fshow () {
  if ($script:is_in_git_repo) { return }
  & "$script:__gitenv__" $script:GITBASH_ENVIRONMENT /usr/bin/bash -c "$script:__append_path__ $script:fshow_command"
}
