{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "adam";
  home.homeDirectory = "/home/adam";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    eza
    keychain
    unzip
    zoxide

    python313Packages.pip
    gnumake
    shellcheck

    python3Minimal
    gcc
    nodejs
    zig
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/starship.toml".source = dots/starship/starship.toml;
    ".config/.transient_prompt".source = dots/starship/.transient_prompt;
    ".config/nvim".source = dots/nvim;
    "Scripts".source = dots/Scripts;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/adam/etc/profile.d/hm-session-vars.sh
  #

  home.sessionVariables = {
    SHELL = pkgs.zsh;
    PATH = "$PATH:/home/adam/Scripts";
    TERM = "xterm-256color";
  };

  systemd.user.services.push-home = {
    Service = {
      ExecStart = "/home/adam/Scripts/push-home";
    };
    serviceConfig = {
      description = "Daily Git squash and push at shutdown";
      Type = "oneshot";
      DefaultDependencies = false;
      RemainAfterExit = true;
    };
    wantedBy = { "default.target" = true; };
    before = { "default.target" = true; };
  };

  # Optional daily timer at 23:59
  systemd.user.timers.push-home = {
    timerConfig = {
      description = "Run push-home daily at 23:59";
      OnCalendar = "*-*-* 23:59";
      Unit = "push-home.service";
      Persistent = false;
    };
    wantedBy = { "timers.target" = true; };
  };

  # zsh setup
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "extract" ];
    };

    zplug = {
      enable = true;
      plugins = [ 
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "zsh-users/zsh-syntax-highlighting"; }
      ];
    };

    localVariables = {
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
    };

    initContent = ''
    # Change Autosuggest Key
    bindkey '^ ' autosuggest-accept
    
    #set up transient prompt
    source ~/.config/.transient_prompt
    '';
    
    shellAliases = {
      c = "clear";

      switch = "sudo nixos-rebuild switch";

      gs = "git status";

      ls = "eza -1   --icons=auto";
      ll = "eza -lha --icons=auto --sort=name --group-directories-first";
      ld = "eza -lhD --icons=auto";
      lt = "eza      --icons=auto --tree";

      polluks = "ssh inf164182@polluks.cs.put.poznan.pl";
    };
  };

  programs.git = {
    enable = true;

    settings.user = {
      name = "Adam Marek";
      email = "118975111+AMarek05@users.noreply.github.com";
    };

    signing = {
      key = "/home/adam/.ssh/git";
      signByDefault = true;
      signer = "ssh";
    };

    settings = {
      gpg.format = "ssh";

      user.useConfigOnly = true;

      init.defaultBranch = "main";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      clang-tools
      gopls
      pyright
      jdt-language-server
      rust-analyzer
      zls
      lua-language-server
      stylua
      bash-language-server
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.keychain = {
    enable = true;
    enableZshIntegration = true;
    keys = [ "git" ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

