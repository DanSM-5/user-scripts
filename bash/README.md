BASH (and utilities) Notes:

## Differences between bash and zsh

Bash and zsh share some functionality due to being POSIX compliant. However there are important differences that you need to be aware of.

- Zsh use base 1 indexes for arrays (WHY THE F\*CK zsh???). Use `setopt KSH_ARRAYS` to fix this behavior.
- Bash and zsh string expansions have subtle differences. Always test the string in both shells.
- In bash double braces regex need to be unquoted. E.g. `[[ thing =~ ing$ ]]`. You can quote the right hand side in zsh.
- In bash, use `shopt -s extglob` to enable advance regex.
- In zsh, you can use `compgen -A` and `compgen -a` if you enable `autoload -U bashcompinit; bashcompinit`

For more information see [Main differences for scripting](https://apple.stackexchange.com/a/361957) in stackexchange.

## Invoke bash an run it within git bash environment (MINGW)

In windows it is complicated to run something under the full MINGW environment from an external process without calling `bash.exe` with the flags for login `-l` and interactive `-i`. However this is not desirable because it makes running things slower as bash will read the .bashrc and other setups for an interactive shell.

A workaround is possible by calling `bash` through `env.exe`. You need to format a command like

```powershell
# Example calling [COMMAND] from powershell
env.exe `
  MSYS=enable_pcon MSYSTEM=MINGW64 enable_pcon=1 `
  SHELL=bash /usr/bin/bash `
  -c "export PATH=`"/mingw64/bin:/usr/local/bin:/usr/bin:/bin:`$PATH`"; [COMMAND]"
```

### Notice

- `MSYS`, `MSYSTEM` and `enable_pcon` environment variables are important.
- Notice that bash is called using a unix path.
- The environment launches but it is missing important MINGW paths.
  - You need to include them in some way like reexporting the `PATH` variable within the `-c` command string.
  - Or include it along with the other variables but it needs to be preprocessed to convert the path to unix format.
- The command that you want to execute has to be located inside the string in `-c` arg.
- It requires careful escaping depending of the complexity of your command.
- You can avoid the command (and the `-c` flag) if you pass a script to bash instead (I'm lazy to write scripts 😅).

For more information see the [bashcall.ps1](../bin/bashcall.ps1) which is a wrapper for the above hack.

## Use rsync in gitbash

The `rsync` package is available for windows in

- scoop main bucket under the name `cwrsync`
- choco with the package name `rsync`

The issue comes with the package being from cygwin with no mingw version.
It has issues with gitbash due to the automatic path conversion applied to paths.
The fix is to set the `MSYS_NO_PATHCONV=1` environment variable though you probably want to do this only for the rsync command.
See example below:

```bash
# Merge target into destination
MSYS_NO_PATHCONV=1 rsync -v -a ./target/ /cygdrive/d/files/tmp/destination/
```

