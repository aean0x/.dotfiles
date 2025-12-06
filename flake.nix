{
  description = "Flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    ...
  } @ inputs: let
    inherit (self) outputs;
    secrets = import (
      if builtins.pathExists ./home/secrets.nix
      then ./home/secrets.nix
      else ./home/secrets.example.nix
    );
    system = "x86_64-linux";
    stateVersion = "25.11";
  in {
    nixosConfigurations.${secrets.hostName} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs stateVersion;};
      modules = [
        ./system/configuration.nix
        ./system/hardware-configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs stateVersion;};
          home-manager.backupFileExtension = "backup";
          home-manager.users."${secrets.username}" = {
            imports = [
              ./home/home.nix
              inputs.nix-flatpak.homeManagerModules.nix-flatpak
            ];
          };
        }
      ];
    };
  };
}
