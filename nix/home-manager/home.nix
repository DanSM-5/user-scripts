{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "$USER";
  home.homeDirectory = "$HOME";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    _7zz
    ast-grep
    bat
    biome
    btop
    # bun
    carapace # create completions for commands
    chafa
    codesnap # make images from code
    # ctop # top command for containers
    # curl
    delta # git diff pager
    dive # explore docker images layers
    doggo # dig like utility
    dua
    duf # disk usage utility
    erdtree
    eza
    fastfetch
    # fclones
    # fdupes
    fd
    ffmpeg
    # fzf
    ghostscript
    gh # github cli
    # gifski # generate gifs
    glow # pretty print md
    go 
    gum
    # gnused
    gron # make json greppable
    gping # ping with graph
    # hyperfine # benchmark tool
    highlight
    imagemagick
    # iputils
    jc # format output of commands as json
    jq
    # jo # easy create json objects
    # jx
    lf
    lazydocker # tui for docker
    # lua-language-server
    luarocks
    # micro
    # mpv
    # mcat # cat images and files
    mdterm # markdown pager
    mkpasswd # encrypt passwords
    # nmap # network discovery tool
    nil # nix-expression-language
    neovim
    oh-my-posh
    onefetch # fastfetch for project directories
    # perl
    # ps
    # poppler # pdf utilities
    # python3
    poppler-utils
    # postgresql
    procs # cross platform process viewer (ps)
    pwgen # generate password
    # rclip # semantic photo searcher
    rclone # copy utility
    ripgrep
    # rustup
    sd # simple sed like
    sad # batch file edit tool
    sqlite
    starship
    # tldr
    tealdeer # tldr client
    # tree
    tree-sitter
    tuicr # github pr tui
    unrar
    # unzip
    upx # compress binaries
    viddy # watch command
    # watchexec # watch changes in a path
    # xidel # extract data from html/xml using css selectors
    yq
    # zig
    # zip
    # zsh
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/daniel/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

