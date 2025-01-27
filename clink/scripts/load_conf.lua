
-- Required environment variables for some scripts
os.setenv('IS_WSL', 'false')
os.setenv('IS_WSL1', 'false')
os.setenv('IS_WSL2', 'false')
os.setenv('IS_TERMUX', 'false')
os.setenv('IS_LINUX', 'false')
os.setenv('IS_MAC', 'false')
os.setenv('IS_WINDOWS', 'true')
os.setenv('IS_GITBASH', 'false')
os.setenv('IS_WINSHELL', 'true')
os.setenv('IS_CMD', 'true')
os.setenv('IS_ZSH', 'false')
os.setenv('IS_BASH', 'false')
os.setenv('IS_POWERSHELL', 'false')
os.setenv('IS_NIXONDROID', 'false')
os.setenv('IS_FROM_CONTAINER', 'false')

local home = os.getenv('USERPROFILE')
os.setenv('HOME', home)
os.setenv('user_scripts_path', home .. '\\user-scripts')
os.setenv('user_conf_path', home .. '\\.usr_conf')
os.setenv('user_config_cache', home .. '\\.cache\\.user_config_cache')
os.setenv('prj', home .. '\\prj')

-- Add ~/.local/bin at the top
os.setenv('PATH', home .. '\\.local\\bin' .. ';'.. home .. '\\bin' .. ';' .. os.getenv('PATH') )
-- Add ~/user-scripts/bin at the bottom
os.setenv('PATH', os.getenv('PATH') .. ';' .. home .. '\\user-scripts\\bin')
os.setenv('EDITOR', 'nvim')
os.setenv('PREFERRED_EDITOR', 'nvim')
os.setenv('BAT_THEME', 'OneHalfDark')
os.setenv('COLORTERM', 'truecolor')
os.setenv('WIN_ROOT', 'C:')
os.setenv('WIN_HOME', home)

-- function lf ()
--   local r = io.popen("pwsh -nolo -nopro -nonin -c '" .. home .. "\\user-scripts\\bin\\lf.ps1'")
--   r.close()
-- end

