{ pkgs, ... }:
{
  imports = [
    ./conf.nix
    ./pangolin.nix
    ./minecraft.nix
  ];

  environment.systemPackages = with pkgs; [ nh ];
  environment.sessionVariables = {
    NH_FLAKE = "/home/adam/sys";
  };
}
