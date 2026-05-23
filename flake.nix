{
  description = "My NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

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
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
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

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:

    let
      customOverlays = final: prev: {
        grimblast = prev.grimblast.override {
          hyprland = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
        };
      };

      hmPkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ customOverlays ];
      };

      commonImports = [
        inputs.sops-nix.nixosModules.sops
        inputs.nix-index-database.nixosModules.default
        (
          { ... }:
          {
            nixpkgs.overlays = [ customOverlays ];
          }
        )
      ];

    in

    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./etc/hosts/nixos.nix
          ]
          ++ commonImports;
        };

        nixos-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./etc/hosts/nixos-laptop.nix
          ]
          ++ commonImports;
        };

        nixos-wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./etc/hosts/nixos-wsl.nix

          ]
          ++ commonImports;
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
            ./modules/forge.nix
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
