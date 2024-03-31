Quake Mode for kitty terminal
================

This is a setup to get a Quake like mode on Kitty terminal using [tdrop](https://github.com/noctuid/tdrop).

# Setup Linux

## Get tdrop

Get tdrop from github and install it.

```bash
git clone https://github.com/noctuid/tdrop $HOME/.config/tdrop
cd $HOME/.config/tdrop
sudo make install
```

## Setup keybinding

Depending on the distro and desktop environment you need to add a keybinding. Preferred keybinding is `` super+` ``.

### General

An option is to use [sxhkd](https://github.com/baskerville/sxhkd) as detailed in tdrop README.

### Linux Mint

In Linux Mint this can be accomplished easily in System Settings > Keyboard > Shorcuts > Custom Shorcuts. You can add the command directly or the script kitty-quake.nix.tdrop.sh which already handles kitty from nix package manager wrapping it in nixGL.

# TODO's

- [ ] Make Quake Like mode for macos.
- [ ] Create non-nix script for kitty (no nixGL)?
- [ ] Test multi monitor setup.
- [ ] Test on Steam Deck.

