{ pkgs, ... }:
{
  home.packages = with pkgs; [
    eza
  ];

  imports = [ ./scripts.nix ];

  # zsh setup
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "extract"
      ];
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

      tt = "tmux";
      tta = "tmux attach";

      gs = "git status";

      ls = "eza -1   --icons=auto --sort=name --group-directories-first";
      ll = "eza -lha --icons=auto --sort=name --group-directories-first";
      ld = "eza -lhD --icons=auto";
      lt = "eza      --icons=auto --tree";

      st = "/mnt/Shared/SillyTavern/SillyTavern/start.sh";

      polluks = "ssh -A inf164182@polluks.cs.put.poznan.pl";

      nhc = "nh clean all --keep 3 --no-gcroots";
      nhco = "nh clean all --keep 3 --no-gcroots --optimise";

      nhu = "nho -u && sleep 3 && nhh";
      nhr = "nho && sleep 3 && nhh";

      nho = "nh os switch";
      nhh = "nh home switch";

      hellfire = "sudo snx-rs -s hellfire.put.poznan.pl -u adam.marek@student.put.poznan.pl -o vpn_Username_Password";

      doom = "/home/adam/.config/emacs/bin/doom";
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
