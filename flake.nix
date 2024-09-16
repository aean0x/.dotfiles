{
  description = "Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flatpaks.url = "github:gmodena/nix-flatpak";
    cursor.url = "github:omarcresp/cursor-flake/main";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    plasma-manager,
    flatpaks,
    cursor,
    ...
  } @ inputs: let
    inherit (self) outputs;
    secrets = import ./home/secrets.nix;
    system = "x86_64-linux";
  in {
    # overlays = import ./overlays {inherit inputs;};

    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix

        flatpaks.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        cursor.packages.${pkgs.system}.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [plasma-manager.homeManagerModules.plasma-manager];

          home-manager.users."${secrets.username}" = {
            imports = [
              ./home/home.nix
              ./home/plasma.nix
              flatpaks.homeManagerModules.nix-flatpak
            ];
          };
        }
      ];
    };
  };
}
