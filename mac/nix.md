Nix package manager in mac
=============

# Install nix package manager

```bash
# Install nix script
# Add `--deamon` for multiuser
curl -L https://nixos.org/nix/install | sh -s -- --darwin-use-unencrypted-nix-store-volume

# Add home manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

**NOTE**: you may need to move the `nixpkgs` from system (sudo) to user nix-channels

# Uninstall nix

Ref: https://iohk.zendesk.com/hc/en-us/articles/4415830650265-Uninstall-nix-on-MacOS

