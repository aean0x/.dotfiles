{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasma = pkgs.callPackage ./aerothemeplasma.nix {};
  # Point to the fetched repository in the Nix store
  repoDir = "${aerothemeplasma}/share/aerothemeplasma/source";
  cfg = config.aerotheme;
in {
  options.aerotheme = {
    enable = lib.mkEnableOption "AeroTheme for KDE Plasma (system-wide)";
    skipBuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Skip rebuilding the theme if it has already been built.
        Enable this to avoid rebuilding the theme on every Nix rebuild.
        Note: You should set this to false when you first install or when you want to force a rebuild.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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

    environment.etc."sddm/themes/sddm-theme-mod/theme.conf.user".text = ''
      [General]
      background=${pkgs.kdePackages.plasma-workspace}/share/wallpapers/Next/contents/images/1920x1080.jpg
      type=image
      enableStartup=true
    '';

    system.activationScripts.aerotheme-sddm = ''
      [ -d /usr/share/sddm/themes/sddm-theme-mod ] || mkdir -p /usr/share/sddm/themes/sddm-theme-mod
      cp -rf ${repoDir}/plasma/sddm/sddm-theme-mod/. /usr/share/sddm/themes/sddm-theme-mod/
    '';

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
  };
}
