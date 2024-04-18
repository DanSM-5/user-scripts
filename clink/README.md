Clink Config Dir
============

# Instructions

1. Install click (scoop prefered)
2. Symlink this directory to $env:LocalAppData\clink
  ```powershell
    New-Item -ItemType SymlinkLink -Target $user_scripts_path\clink -Path $env:LocalAppData\clink
  ```
3. Open cmd and enter `clink inject`
4. Add the `scripts` directory to the installscripts path
  ```cmd
    clink installscripts %LOCALAPPDATA%\clink\scripts
  ```

# Optional Steps

## Enable fzf keybindings

In cmd run:
```cmd
clink set fzf.default_bindings true
```

See more in [fzf click wrapper](https://github.com/chrisant996/clink-fzf)

