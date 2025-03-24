{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasma = pkgs.callPackage ./aerothemeplasma.nix {};
  # Point to the fetched repository in the Nix store
  repoDir = "${aerothemeplasma}/share/aerothemeplasma/source";
in {
  environment.systemPackages = [
    aerothemeplasma
    pkgs.gnutar
    pkgs.gzip
  ];
  virtualisation.docker.enable = true;

  services.displayManager.sddm = {
    enable = true;
    settings.Theme.Current = "sddm-theme-mod";
  };

  # Install Segoe UI fonts
  fonts = {
    packages = with pkgs; [corefonts vistafonts fira fira-code fira-mono];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = ["Segoe UI"];
        serif = ["Segoe UI"];
        monospace = ["Consolas"];
      };
    };
  };

  environment.etc."icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=aero-drop
  '';

  system.activationScripts.aerotheme-cursor = ''
    [ -d /usr/share/icons/aero-drop ] || mkdir -p /usr/share/icons/aero-drop
    ${pkgs.gnutar}/bin/tar --use-compress-program=${pkgs.gzip}/bin/gzip -xf ${repoDir}/misc/cursors/aero-drop.tar.gz -C /usr/share/icons/aero-drop --strip-components=1
  '';
}
