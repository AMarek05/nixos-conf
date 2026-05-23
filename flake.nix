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

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({
      systems = [ "x86_64-linux" ];

      perSystem = { pkgs', ... }: {
        packages = {};
        devShells.default = pkgs'.mkShell { };
      };

      # ─── Host list ───────────────────────────────────────────────────
      hosts = [ "nixos" "nixos-laptop" "nixos-wsl" ];

      _module.args = { inherit (self) hosts; };

      # ─── NixOS configurations ──────────────────────────────────────────
      flake.nixosConfigurations =
        let
          lib = inputs.nixpkgs.lib;
          customOverlays = final: prev: {
            grimblast = prev.grimblast.override {
              hyprland = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
            };
          };
          commonImports = [
            inputs.sops-nix.nixosModules.sops
            inputs.nix-index-database.nixosModules.default
            ({ ... }: { nixpkgs.overlays = [ customOverlays ]; })
          ];
          mkNixos = name: lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              ./etc/hosts/${name}.nix
              ./etc/hosts/default.nix
            ] ++ commonImports;
          };
        in
          builtins.listToAttrs (
            map (name: lib.name-value-pair name (mkNixos name)) hosts
          )
          // {
            # WSL has a different generator + extra module
            nixos-wsl = lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [
                ./etc/hosts/nixos-wsl.nix
                ./etc/hosts/default.nix
                inputs.nixos-wsl.nixosModules.default
              ] ++ builtins.filter (m: m != inputs.nixos-wsl.nixosModules.default) commonImports;
            };
          };

      # ─── Home-manager configurations ───────────────────────────────────
      flake.homeConfigurations =
        let
          lib = inputs.nixpkgs.lib;
          hmLib = inputs.home-manager.lib;
          mkHm = name: hmLib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
            modules = [
              ./hosts/${name}.nix
            ] ++ lib.optional (!(lib.hasSuffix "-wsl" name)) ./modules/forge.nix;
            extraSpecialArgs = { inherit inputs; };
          };
        in
          builtins.listToAttrs (
            map (name: lib.name-value-pair "adam@${name}" (mkHm name)) hosts
          );
    });
}