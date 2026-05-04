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

        # Set up transient prompt
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

        st = "/home/adam/sync/SillyTavern/start.sh";

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
      enableZshIntegration = true;
      keys = [ "git" ];
    };
  };
}
