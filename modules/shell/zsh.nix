# shell/zsh module — interactive zsh setup, aliases, and shell utilities
{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.modules.shell.zsh;
in
{
  options.modules.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      eza
      rsync
      snx-rs
      nh
    ];

    xdg.configFile."zsh/.p10k.zsh".source = ../../store/starship/.p10k.zsh;

    programs.ghostty.enableZshIntegration = lib.mkForce false;

    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
      ];

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "extract"
        ];
      };

      localVariables = {
        ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      };

      initContent = lib.mkMerge [
        (lib.mkBefore ''
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        '')

        (lib.mkAfter ''
          [[ ! -f "$ZDOTDIR/.p10k.zsh" ]] || source "$ZDOTDIR/.p10k.zsh"


          # Change Autosuggest Key
          bindkey '^ ' autosuggest-accept

          eval $(keychain --quiet --eval git)
        '')
      ];

      shellAliases = {
        c = "clear";
        tt = "tmux";
        tta = "tmux attach";
        gs = "git status";

        ls = "eza -1   --icons=auto --sort=name --group-directories-first";
        ll = "eza -lha --icons=auto --sort=name --group-directories-first";
        ld = "eza -lhD --icons=auto";
        lt = "eza      --icons=auto --tree";

        st = "${pkgs.sillytavern}/bin/sillytavern";
        polluks = "ssh -A inf164182@polluks.cs.put.poznan.pl";

        nhc = "nh clean all --keep 3 --no-gcroots";
        nhco = "nh clean all --keep 3 --no-gcroots --optimise";
        nhu = "nho -u && sleep 3 && nhh";
        nhr = "nho && sleep 3 && nhh";
        nho = "nh os switch";
        nhh = "nh home switch";

        rsync = "rsync --info=progress2";
        hellfire = "sudo snx-rs -s hellfire.put.poznan.pl -u adam.marek@student.put.poznan.pl -o vpn_Username_Password";
        doom = "/home/adam/.config/emacs/bin/doom";
        read-sops = "SOPS_AGE_KEY=$(${pkgs.ssh-to-age}/bin/ssh-to-age -- -private-key -i ~/.ssh/age) ${pkgs.sops}/bin/sops -- ~/sys/secrets/openclaw.yaml";
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    programs.keychain = {
      enable = true;
      enableZshIntegration = false;
      keys = [ "git" ];
    };
  };
}
