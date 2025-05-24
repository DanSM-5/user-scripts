Go Notes
=========

## Shebang to execute go in unix

See next go snippet for a working shebang in go

Ref: https://stackoverflow.com/questions/7707178/whats-the-appropriate-go-shebang-line

```go
///usr/bin/env true; exec /usr/bin/env go run "$0" "$@"

package main

import "fmt"

func main() {
  fmt.Println("Go code here")
}
```

Other alternatives:

```go
///usr/bin/env go run "$0" "$@"; exit
```

It needs `; exit` at the end to stop parsing the file as a shell script.

```go
///bin/sh -c true && exec /usr/bin/env go run "$0" "$@"
```

Using `/bin/sh` for portability

### Explanation

The **shebang** in question is not a proper one `#!`. It first executes as a shell script
which happens to have its first line as a valid go comment. This is important because when executed,
go won't fail for invalid syntax in the file.
Everything after `//` is ignored. Shell code will ignore extra `/`, so the extra initial slashes are ignored.
[Ref](https://unix.stackexchange.com/questions/162531/shebang-starting-with/162535#162535)

The initial command `/usr/bin/env true` is a noop command. It calls the `true` binary which always returns 0.
It uses `env` to find it in the environmet for non-common installations where there is no `/usr/bin/true` or
`/bin/true`.

Then it uses `exec` builtin to do a replacement of the current process instead of forking a children.
A similar strategy `/usr/bin/env go` is used to run go from the environmet.
There 3 argumenst are passed:

- `run`: The subcommand for to run a given script
- `"$0"`: Variable that expands to the name of the script
- `"$@"`: All arguments passed to the script. This forwards the arguments to the go script
