{ pkgs, lib, ... }:
{
  programs.zsh.enable = true;

  users.users.adam = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJD19KUXlKFCM0ZD57Qgj6A+JyE2kHTj/AM14fm1VYPa 118975111+AMarek05@users.noreply.github.com"
    ];
  };

  networking.hostName = lib.mkDefault "nixos-wsl";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.pathsToLink = [ "/share/zsh/" ];

  environment.systemPackages = with pkgs; [
    git
    neovim

    man-pages

    rclone
  ];

  programs.direnv = {
    enable = true;
    silent = true;

    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
