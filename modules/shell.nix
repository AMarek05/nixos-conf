{ ... }:
{
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
    
    #Set up transient prompt
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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
}
