
-- Required environment variables for some scripts
os.setenv('IS_WSL', 'false')
os.setenv('IS_WSL1', 'false')
os.setenv('IS_WSL2', 'false')
os.setenv('IS_TERMUX', 'false')
os.setenv('IS_LINUX', 'false')
os.setenv('IS_MAC', 'false')
os.setenv('IS_GITBASH', 'false')
os.setenv('IS_WINDOWS', 'true')
os.setenv('IS_POWERSHELL', 'false')
os.setenv('IS_CMD', 'true')

home = os.getenv('USERPROFILE')
os.setenv('HOME', home)
os.setenv('user_scripts_path', home .. '\\user-scripts')
os.setenv('user_conf_path', home .. '\\.usr_conf')
os.setenv('prj', home .. '\\prj')

os.setenv('PATH', os.getenv('PATH') .. ';' .. home .. '\\user-scripts\\bin')

-- function lf ()
--   local r = io.popen("pwsh -nolo -nopro -nonin -c '" .. home .. "\\user-scripts\\bin\\lf.ps1'")
--   r.close()
-- end
