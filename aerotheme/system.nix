{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasmaPkgs = pkgs.callPackage ./aerothemeplasma.nix {inherit pkgs;};
  inherit (aerothemeplasmaPkgs) decoration smodsnap smodglow startupfeedback aeroglassblur aeroglide aerothemeplasma aerothemeplasma-git corebindingsplugin seventasks sevenstart desktopcontainment;
in {
  environment.sessionVariables = {
    # TODO: find a better way to do this than system session variables.
    QT_PLUGIN_PATH = "${aerothemeplasma}/lib/qt-6/plugins:${decoration}/lib/qt-6/plugins:$QT_PLUGIN_PATH";
    QML2_IMPORT_PATH = "${aerothemeplasma}/lib/qt-6/qml:$QML2_IMPORT_PATH";
    QML_DISABLE_DISTANCEFIELD = "1";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    decoration
    smodsnap
    smodglow
    startupfeedback
    aeroglassblur
    aeroglide
    aerothemeplasma
    corebindingsplugin
    seventasks
    sevenstart
    desktopcontainment
    kdePackages.qtstyleplugin-kvantum
    kdePackages.plasma5support
    shared-mime-info
    kdePackages.kitemmodels
    kdePackages.kitemviews
    kdePackages.knewstuff
    kdePackages.kcmutils
  ];

  system.activationScripts.updateMimeDatabase = lib.stringAfter ["etc"] ''
    ${pkgs.shared-mime-info}/bin/update-mime-database /etc/xdg/mime
  '';

  # SDDM configuration
  services.displayManager.sddm = {
    enable = true;
    theme = "sddm-theme-mod";
    settings = {
      Theme = {
        CursorTheme = "aero-drop";
      };
    };
  };

  # Fonts
  fonts = {
    packages = with pkgs; [
      corefonts
      vistafonts
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = ["Segoe UI"];
        serif = ["Segoe UI"];
        monospace = ["Hack"];
      };
    };
  };
}
