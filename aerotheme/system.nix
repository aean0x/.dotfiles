{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: let
      # Build packages using prev (before overlay) to avoid recursion
      aerothemePkgs = prev.callPackage ./aerothemeplasma.nix {
        originalLibplasma = prev.kdePackages.libplasma;
      };
    in {
      kdePackages =
        prev.kdePackages
        // {
          libplasma = aerothemePkgs.customLibplasma;
        };
      # Make aerotheme packages available in the final package set
      inherit (aerothemePkgs) decoration smodsnap smodglow startupfeedback aeroglassblur aeroglide aerothemeplasma aerothemeplasma-git seventasks sevenstart desktopcontainment;
    })
  ];

  # Rest of your configuration remains unchanged
  environment.sessionVariables = {
    QT_PLUGIN_PATH = "${pkgs.aerothemeplasma}/lib/qt-6/plugins:${pkgs.decoration}/lib/qt-6/plugins:$QT_PLUGIN_PATH";
    QML2_IMPORT_PATH = "${pkgs.aerothemeplasma}/lib/qt-6/qml:$QML2_IMPORT_PATH";
    QML_DISABLE_DISTANCEFIELD = "1";
  };

  environment.systemPackages = with pkgs; [
    decoration
    smodsnap
    smodglow
    startupfeedback
    aeroglassblur
    aeroglide
    (lib.hiPrio aerothemeplasma) # High priority to override default KDE files
    seventasks
    sevenstart
    desktopcontainment

    kdePackages.qtstyleplugin-kvantum
    kdePackages.plasma5support
    kdePackages.kdeplasma-addons
    kdePackages.sddm-kcm
    kdePackages.plasma-browser-integration
    kdePackages.partitionmanager
    kdePackages.qttools
    kdePackages.qtvirtualkeyboard
    kdePackages.qt5compat
    kdePackages.plasma-wayland-protocols
    kdePackages.extra-cmake-modules
    kdePackages.qtbase
    kdePackages.qtquick3d
    kdePackages.qtquicktimeline
    kdePackages.qtquick3dphysics
    kdePackages.qtdeclarative

    shared-mime-info
    kdePackages.kitemmodels
    kdePackages.kitemviews
    kdePackages.knewstuff
    kdePackages.kcmutils
  ];

  system.activationScripts.updateMimeDatabase = lib.stringAfter ["etc"] ''
    ${pkgs.shared-mime-info}/bin/update-mime-database /etc/xdg/mime
  '';

  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = false;
  };
  services.xserver = {
    enable = true;
  };
  services.displayManager.sddm = {
    enable = true;
    theme = "sddm-theme-mod";
    settings = {
      Theme = {
        CursorTheme = "aero-drop";
      };
    };
  };

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
