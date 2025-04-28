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
    # QML_DISABLE_DISTANCEFIELD = "1";
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
    kdePackages.kdeplasma-addons
    kdePackages.sddm-kcm
    kdePackages.yakuake
    kdePackages.skanlite
    kdePackages.kdenlive
    kdePackages.okular
    kdePackages.elisa
    kdePackages.kcalc
    kdePackages.ksystemlog
    kdePackages.kolourpaint
    kdePackages.isoimagewriter
    kdePackages.plasma-browser-integration
    kdePackages.partitionmanager
    kdePackages.qttools
    kdePackages.full
    kdePackages.qtvirtualkeyboard
    kdePackages.qt5compat
    kdePackages.plasma-wayland-protocols
    kdePackages.extra-cmake-modules
    kdePackages.qtbase
    kdePackages.qtquick3d
    kdePackages.qtquicktimeline
    kdePackages.qtquick3dphysics
    kdePackages.qtdeclarative
    kdePackages.appstream-qt
  ];

  system.activationScripts.updateMimeDatabase = lib.stringAfter ["etc"] ''
    ${pkgs.shared-mime-info}/bin/update-mime-database /etc/xdg/mime
  '';

  # KDE Plasma and SDDM configuration
  services.desktopManager.plasma6.enable = true;
  services.xserver = {
    enable = true;
  };
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
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
