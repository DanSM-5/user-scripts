{ pkgs, ...}: {
  home.packages = with pkgs; [
    bat
    btop
    delta
    erdtree
    fastfetch
    fd
    ffmpeg
    fzf
    glow
    home
    jq
    lf
    micro
    neovim
    nix
    oh
    ripgrep
    sqlite
    starship
    tldr
    unrar
  ];
}
