{
  description = "Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    plasma-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    secrets = import ./home/secrets.nix;
    system = "x86_64-linux";

    overlays = [
      (final: prev: {
        aerothemeplasma = prev.callPackage ./aerotheme/aerothemeplasma.nix {};
        stable = import nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      })
    ];
  in {
    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        {nixpkgs.overlays = overlays;}
        ./configuration.nix
        ./hardware-configuration.nix
        ./aerotheme/system.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [plasma-manager.homeManagerModules.plasma-manager];
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.backupFileExtension = "backup";
          home-manager.users."${secrets.username}" = {
            imports = [
              ./home/home.nix
              ./aerotheme/user.nix
            ];
          };
        }
      ];
    };
  };
}
