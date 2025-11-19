{
  description = "My NixOS Flake Configuration";

  inputs = {
    # Nixpkgs is the primary source of packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs : {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./etc/configuration.nix 

          ./etc/hosts/nixos-hardware.nix

          {
            networking.hostName = nixpkgs.lib.mkForce "nixos";
          }
        ];
      };
      nixos-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./etc/configuration.nix 

          ./etc/hosts/laptop-hardware.nix

          {
            networking.hostName = nixpkgs.lib.mkForce "nixos-laptop";
          }
        ];
      };
    };
    homeConfigurations = {
      "adam@nixos" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";

        modules = [
          ./home.nix
        ];

        extraSpecialArgs = {
          inherit inputs;
        };
      };
      "adam@nixos-laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";

        modules = [
          ./hosts/nixos-laptop.nix
        ];

        extraSpecialArgs = {
          inherit inputs;
        };
      };
    };
  };
}
