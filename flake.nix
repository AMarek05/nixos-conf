{
  description = "My NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

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
      url = "github:quickshell-mirror/quickshell";
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
      url = "git+https://git.amarek.pl/amarek-inc/forge.git";
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

    flake-parts.url = "github:hercules-ci/flake-parts";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    fff = {
      url = "github:dmtrKovalenko/fff";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    attic = {
      url = "github:zhaofengli/attic";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      let
        lib = inputs.nixpkgs.lib;
        hmLib = inputs.home-manager.lib;
        myLib = {
          toLua = import ./lib/toLua.nix { inherit lib; };
          git-wrapper = import ./lib/git.nix;
          fj-wrapper = import ./lib/fj.nix;
        };

        hosts = {
          "nixos" = {
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
          };
          "nixos-laptop" = {
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
          };
          "nixos-server" = {
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
          };
          "nixos-wsl" = {
            nixpkgs = inputs.nixpkgs;
            system = "x86_64-linux";
          };
          "nixos-oci" = {
            nixpkgs = inputs.nixpkgs-stable;
            system = "aarch64-linux";
          };
        };

        grimblastOverlay = final: prev: {
          grimblast = prev.grimblast.override {
            hyprland = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
          };
        };

        commonImports = [
          inputs.sops-nix.nixosModules.sops
          inputs.nix-index-database.nixosModules.default
        ];

        mkNixos =
          name:
          { nixpkgs, system }:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs myLib; };
            modules = [
              ./modules/nixos/default.nix
              ./hosts/nixos/${name}.nix
            ]
            ++ commonImports;
          };

        mkHm =
          name:
          { nixpkgs, system }:
          hmLib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [ grimblastOverlay ];
            };
            modules = [
              ./hosts/hm/${name}.nix
            ];
            extraSpecialArgs = {
              inherit inputs myLib;
              osConfig = nixosCfgs.${name}.config;

              osConfigs = nixosCfgs;
            };
          };

        nixosCfgs = builtins.mapAttrs mkNixos hosts;

        homeCfgs = builtins.listToAttrs (
          lib.mapAttrsToList (name: hostAttrs: {
            name = "adam@${name}";
            value = mkHm name hostAttrs;
          }) hosts
        );

      in
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake.nixosConfigurations = nixosCfgs;
        flake.homeConfigurations = homeCfgs;

        flake.packages.x86_64-linux.ociImage = nixosCfgs."nixos-oci".config.system.build.image;
      }
    );
}
