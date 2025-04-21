{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasmaPkgs = pkgs.callPackage ./aerothemeplasma.nix {inherit pkgs;};
  inherit (aerothemeplasmaPkgs) decoration smodsnap smodglow startupfeedback aeroglassblur aeroglide aerothemeplasma aerothemeplasma-git corebindingsplugin;

  # Add the dereference workaround
  derefDecoration = pkgs.runCommand "smod-decoration-workaround" {} ''
    cp -r --dereference ${decoration}/lib/qt-6/plugins $out
  '';
in {
  environment.sessionVariables = {
    QT_PLUGIN_PATH = ["${derefDecoration}"];
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

  # Install SDDM theme
  # environment.etc."sddm.conf.d/theme.conf".text = ''
  #   [Theme]
  #   Current=sddm-theme-mod
  #   CursorTheme=aero-drop
  # '';

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
