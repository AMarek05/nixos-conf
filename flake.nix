{
  description = "My NixOS Flake Configuration";

  inputs = {
    # Nixpkgs is the primary source of packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./etc/configuration.nix
            ./etc/hosts/nixos-hardware.nix

            ./etc/nvidia.nix
            {
              networking.hostName = nixpkgs.lib.mkForce "nixos";
            }
          ];
        };
        nixos-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./etc/configuration.nix

            ./etc/hosts/laptop-hardware.nix

            {
              networking.hostName = nixpkgs.lib.mkForce "nixos-laptop";
              boot.loader.grub.enable = nixpkgs.lib.mkForce false;
              boot.loader.systemd-boot.enable = nixpkgs.lib.mkForce true;
              boot.loader.efi.canTouchEfiVariables = nixpkgs.lib.mkForce true;
            }
          ];
        };
      };
      homeConfigurations = {
        "adam@nixos" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";

          modules = [
            ./hosts/nixos.nix
          ];

          extraSpecialArgs = {
            inherit inputs;
          };
        };
        "adam@nixos-laptop" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";

          modules = [
            ./hosts/nixos-laptop.nix
            {
              wayland.windowManager.hyprland.settings = {
                monitor = nixpkgs.lib.mkForce [ ", preferred, auto, 1" ];
                "$mod" = nixpkgs.lib.mkForce "Alt";
                exec-once = [ "uwsm app -- ghostty" ];
              };
            }
          ];
          extraSpecialArgs = {
            inherit inputs;
          };
        };
      };
    };
}
