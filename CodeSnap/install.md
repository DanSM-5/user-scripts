# Windows


```powershell
# With scoop
scoop install codesnap

# Building from source
# This requires a bunch of dependencies 😅
scoop install vcpkg
vcpkg install openssl
$env:OPENSSL_NO_VENDOR = "$HOME\scoop\persist\vcpkg\packages\openssl_x64-windows"
cargo install codesnap-cli
```

