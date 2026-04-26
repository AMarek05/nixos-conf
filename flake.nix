{
  description = "My NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    hyprland.url = "github:hyprwm/Hyprland";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";

      inputs.lix.url = "git+https://git.lix.systems/lix-project/lix";
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
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    forge = {
      url = "github:AMarek05/forge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-openclaw,
      sops-nix,
      lix-module,
      ...
    }@inputs:

    let
      openldapOverlay = final: prev: {
        openldap =
          if prev.stdenv.hostPlatform.isi686 then
            prev.openldap.overrideAttrs (old: {
              doCheck = false;
            })
          else
            prev.openldap;
      };

      lixToolsOverlay = final: prev: {
        inherit (prev.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      };

      hmPkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;

        overlays = [
          openldapOverlay
          lixToolsOverlay
        ];
      };

      sharedModules = [
        ./etc/configuration.nix
        sops-nix.nixosModules.sops

        lix-module.nixosModules.default

        {
          nixpkgs.overlays = [
            openldapOverlay
            lixToolsOverlay
          ];
        }
      ];
    in

    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = sharedModules ++ [
            ./etc/hosts/nixos-hardware.nix
            ./etc/openclaw.nix
            nix-openclaw.nixosModules.openclaw-gateway
            ./etc/nvidia.nix
            {
              networking.hostName = nixpkgs.lib.mkForce "nixos";
            }
          ];
        };
        nixos-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = sharedModules ++ [
            ./etc/hosts/laptop-hardware.nix

            {
              networking.hostName = nixpkgs.lib.mkForce "nixos-laptop";

              boot.loader.grub.enable = nixpkgs.lib.mkForce false;
              boot.loader.systemd-boot.enable = nixpkgs.lib.mkForce true;
              # boot.loader.efi.canTouchEfiVariables = nixpkgs.lib.mkForce true;

              boot.kernelParams = [ "i915.enable_dpcd_backlight=3" ];

              services.upower.enable = true;
              systemd.tmpfiles.rules = [
                "w /sys/class/power_supply/BAT1/charge_control_end_threshold - - - - 85"
              ];
            }
          ];
        };
        nixos-wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = sharedModules ++ [
            ./etc/configuration-wsl.nix

            inputs.nixos-wsl.nixosModules.default
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
          pkgs = hmPkgs;

          modules = [
            ./hosts/nixos.nix
            ./modules/forge.nix
          ];

          extraSpecialArgs = {
            inherit inputs;
          };
        };

        "adam@nixos-laptop" = home-manager.lib.homeManagerConfiguration {
          pkgs = hmPkgs;

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
            }
          ];

          extraSpecialArgs = {
            inherit inputs;
          };
        };

        "adam@nixos-wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = hmPkgs;

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
