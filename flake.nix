{
  description = "My NixOS Flake Configuration";

  inputs = {
    # Nixpkgs is the primary source of packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    hyprland.url = "github:hyprwm/Hyprland";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
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
              boot.kernelParams = [ "i915.enable_dpcd_backlight=3" ];
            }
          ];
        };
        nixos-wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            inputs.nixos-wsl.nixosModules.default
            ./etc/configuration-wsl.nix
            {
              networking.hostName = nixpkgs.lib.mkForce "nixos-wsl";
              system.stateVersion = "25.05";
              wsl.enable = true;
              wsl.defaultUser = "adam";
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
                monitor = nixpkgs.lib.mkForce [ ", 1920x1080@59.997000, auto, 1" ];
                input.touchpad = {
                  natural_scroll = true;
                  scroll_factor = 0.3;
                };
              };
              programs.ashell.settings.modules.right = nixpkgs.lib.mkForce [
                "SystemInfo"
                [
                  "Clock"
                  "Privacy"
                ]
                "Battery"
                "Settings"
              ];
            }
          ];

          extraSpecialArgs = {
            inherit inputs;
          };
        };
        "adam@nixos-wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";

          modules = [
            ./hosts/nixos-wsl.nix
          ];

          extraSpecialArgs = {
            inherit inputs;
          };
        };
      };
    };
}
