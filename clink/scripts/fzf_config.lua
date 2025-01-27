-- Workaround for diagnostics
os.setenv = os.setenv

local home = os.getenv('USERPROFILE') or ''
local user_conf_path = home .. '\\.usr_conf'
local user_scripts_path = home .. '\\user-scripts'
local fzf_preview_script = home .. '\\.usr_conf\\utils\\fzf-preview.ps1'
local fzf_copy_helper = home .. '\\.usr_conf\\utils\\copy-helper.ps1'
local fzf_log_helper = home .. '\\.usr_conf\\utils\\log-helper.ps1'
local fzf_ctrlt_script = user_conf_path .. '\\fzf\\ctrl_t_command.bat'
local fzf_altc_script = user_conf_path .. '\\fzf\\alt_c_command.bat'

FD_SHOW_OPTIONS_LIST = {
  '--follow',
  '--hidden',
  '--no-ignore'
}

FD_EXCLUDE_OPTIONS_LIST = {
  '--exclude', 'AppData',
  '--exclude', 'Android',
  '--exclude', 'OneDrive',
  '--exclude', 'Powershell',
  '--exclude', 'node_modules',
  '--exclude', 'plugged',
  '--exclude', 'tizen-studio',
  '--exclude', 'Library',
  '--exclude', 'scoop',
  '--exclude', 'vimfiles',
  '--exclude', 'aws',
  '--exclude', 'pipx',
  '--exclude', '.vscode-server',
  '--exclude', '.vscode-server-server',
  '--exclude', '.git',
  '--exclude', '.gitbook',
  '--exclude', '.gradle',
  '--exclude', '.nix-defexpr',
  '--exclude', '.azure',
  '--exclude', '.SpaceVim',
  '--exclude', '.cache',
  '--exclude', '.jenv',
  '--exclude', '.node-gyp',
  '--exclude', '.npm',
  '--exclude', '.nvm',
  '--exclude', '.colima',
  '--exclude', '.pyenv',
  '--exclude', '.DS_Store',
  '--exclude', '.vscode',
  '--exclude', '.vim',
  '--exclude', '.bun',
  '--exclude', '.nuget',
  '--exclude', '.dotnet',
  '--exclude', '.pnpm-store',
  '--exclude', '.pnpm*',
  '--exclude', '.zsh_history.*',
  '--exclude', '.android',
  '--exclude', '.sony',
  '--exclude', '.chocolatey',
  '--exclude', '.gem',
  '--exclude', '.jdks',
  '--exclude', '.nix-profile',
  '--exclude', '.sdkman',
  '--exclude', '__pycache__',
  '--exclude', '.local/pipx/*',
  '--exclude', '.local/share/*',
  '--exclude', '.local/state/*',
  '--exclude', '.local/lib/*',
  '--exclude', 'cache',
  '--exclude', 'browser-data',
  '--exclude', 'go',
  '--exclude', 'nodejs',
  '--exclude', 'podman',
  '--exclude', 'PlayOnLinux*',
  '--exclude', '.PlayOnLinux',
}

FD_EXCLUDE_OPTIONS = table.concat(FD_EXCLUDE_OPTIONS_LIST, ' ')
FD_SHOW_OPTIONS = table.concat(FD_SHOW_OPTIONS_LIST, ' ')
FD_OPTIONS = FD_SHOW_OPTIONS .. ' ' .. FD_EXCLUDE_OPTIONS

local preview_window_binding = table.concat({
  '--bind', '"ctrl-/:change-preview-window(down|hidden|)"',
  '--bind', '"ctrl-^:toggle-preview"'
}, ' ')
local common_bindings = table.concat({
  '--bind', 'alt-a:select-all',
  '--bind', 'alt-d:deselect-all',
  '--bind', 'alt-f:first',
  '--bind', 'alt-l:last',
  '--bind', 'alt-c:clear-query',
  '--bind', 'alt-up:preview-page-up,alt-down:preview-page-down',
  '--bind', 'ctrl-s:toggle-sort',
}, ' ')
local common_opts = table.concat({
  '--ansi', '--cycle',
  '--input-border',
}, ' ')
local fzf_default_cmd = table.concat({
  'rg', '--files',
  '--no-ignore', '--hidden', '--follow',
  '--glob', '"!.git"',
  '--glob', '"!node_modules"',
}, ' ')
local fzf_ctrlt_cmd = table.concat({
  fzf_ctrlt_script
}, ' ')
local fzf_altc_cmd = table.concat({
  fzf_altc_script,
}, ' ')

local shome = home:gsub([[\]], '/')
local sconf = user_conf_path:gsub([[\]], '/')
local scrip = user_scripts_path:gsub([[\]], '/')
local fzf_hist_dir = shome .. '/.cache/fzf-history'
local def_history = '--history=' .. fzf_hist_dir .. '/fzf-history-default'
local ctrlr_history = '--history=' .. fzf_hist_dir .. '/fzf-history-ctrlr'
local ctrlt_history = '--history=' .. fzf_hist_dir .. '/fzf-history-ctrlt'
local altc_history = '--history=' .. fzf_hist_dir .. '/fzf-history-altc'

local fzf_default_opts = table.concat({
  def_history,
  '--height=80%',
  '--layout=reverse', '--border', '--color=dark',
  '--color="fg:-1,bg:-1,hl:#c678dd,fg+:#ffffff,bg+:#4b5263,hl+:#d858fe"',
  '--color="info:#98c379,prompt:#61afef,pointer:#be5046,marker:#e5c07b,spinner:#61afef,header:#61afef"',
}, ' ')

local fzf_ctrlr_opts = table.concat({
  ctrlr_history,
  common_bindings,
  common_opts,
  '--with-shell', '"pwsh -NoProfile -NonInteractive -NoLogo -Command"',
  '--preview', '"' .. fzf_log_helper .. ' {}"',
  '--preview-window', 'up:3:hidden:wrap',
  '--bind', 'ctrl-/:toggle-preview',
  '--bind', '"ctrl-y:execute-silent(' .. fzf_copy_helper .. ' {})+abort"',
  '--color', 'header:italic',
  '--prompt', '"History> "',
  '--header', '"ctrl-y: Copy"',
}, ' ')

local fzf_ctrlt_opts = table.concat({
  ctrlt_history,
  common_bindings,
  preview_window_binding,
  common_opts,
  '--with-shell', '"pwsh -NoProfile -NonInteractive -NoLogo -Command"',
  '--preview', '"' .. fzf_preview_script .. ' . {}"',
  '--multi', '--ansi', '--cycle',
  '--header', '"ctrl-a: All | ctrl-d: Dirs | ctrl-f: Files | ctrl-y: Copy | ctrl-t: CWD"',
  '--prompt', '"All> "',
  '--bind', '"ctrl-a:change-prompt(All >)+reload(' .. fzf_ctrlt_script .. ')"',
  '--bind', '"ctrl-f:change-prompt(Files >)+reload('.. fzf_ctrlt_script .. ' --type file)"',
  '--bind', '"ctrl-d:change-prompt(Dirs >)+reload(' .. fzf_altc_script .. ')"',
  '--bind', '"ctrl-t:change-prompt(CWD >)+reload(eza --color=always --all --oneline --dereference --group-directories-first)"',
  '--bind', '"ctrl-y:execute-silent(' .. fzf_copy_helper .. ' {+f})+abort"',
  '--bind', '"ctrl-o:execute-silent(Start-Process {})+abort"',
  '--preview-window', '"60%"',
}, ' ')

local fzf_altc_opts = table.concat({
  altc_history,
  common_bindings,
  preview_window_binding,
  common_opts,
  '--header', '"ctrl-a: CD | ctrl-d: Up | ctrl-e: Config | ctrl-r: Scripts | ctrl-t: CWD | ctrl-w: Projects"',
  '--with-shell', '"pwsh -NoProfile -NonInteractive -NoLogo -Command"',
  '--preview', '"' .. fzf_preview_script .. ' . {}"',
  '--prompt "CD> "',
  '--color header:italic',
  '--preview-window', '60%',
  '--bind', '"ctrl-t:change-prompt(CWD> )+reload(eza -A --show-symlinks --color=always --only-dirs --dereference --no-quotes --oneline $PWD)"',
  '--bind', '"ctrl-a:change-prompt(CD> )+reload(' .. fzf_altc_script .. ')"',
  '--bind', '"ctrl-u:change-prompt(Up> )+reload(' .. fzf_altc_script .. ' . ..)"',
  '--bind', '"ctrl-e:change-prompt(Scripts> )+reload(echo '.. sconf .. ' ; ' .. fzf_altc_script .. ' . ' .. sconf .. ')"',
  '--bind', '"ctrl-r:change-prompt(Config> )+reload(echo '.. scrip .. ' ; ' .. fzf_altc_script .. ' . ' .. scrip .. ')"',
  '--bind', '"ctrl-w:change-prompt(Projects> )+reload('.. fzf_altc_script .. ' . ' .. shome .. '/projects)"',
}, ' ')

-- History location for fzf
os.setenv('FZF_HIST_DIR', fzf_hist_dir)
-- fd show and exclude options
os.setenv('FD_SHOW_OPTIONS', FD_SHOW_OPTIONS)
os.setenv('FD_EXCLUDE_OPTIONS', FD_EXCLUDE_OPTIONS)
os.setenv('FD_OPTIONS', FD_OPTIONS)
-- fzf variables: commands
os.setenv('FZF_DEFAULT_COMMAND', fzf_default_cmd)
os.setenv('FZF_CTRL_T_COMMAND', fzf_ctrlt_cmd)
os.setenv('FZF_ALT_C_COMMAND', fzf_altc_cmd)
-- fzf variables: options
os.setenv('FZF_DEFAULT_OPTS', fzf_default_opts)
os.setenv('FZF_CTRL_R_OPTS', fzf_ctrlr_opts)
os.setenv('FZF_CTRL_T_OPTS', fzf_ctrlt_opts)
os.setenv('FZF_ALT_C_OPTS', fzf_altc_opts)

