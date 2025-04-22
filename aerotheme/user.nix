{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasmaPkgs = pkgs.callPackage ./aerothemeplasma.nix {inherit pkgs;};
  inherit (aerothemeplasmaPkgs) aerothemeplasma aerothemeplasma-git;
in {
  home.file = {
    # I hate how much time I spent trying to get this to work without the home symlinks. I give up.
    ".local/share/plasma/desktoptheme".source = "${aerothemeplasma-git}/plasma/desktoptheme";
    ".local/share/plasma/look-and-feel".source = "${aerothemeplasma-git}/plasma/look-and-feel";
    ".local/share/plasma/plasmoids".source = "${aerothemeplasma-git}/plasma/plasmoids";
    ".local/share/plasma/layout-templates".source = "${aerothemeplasma-git}/plasma/layout-templates";
    ".local/share/plasma/shells".source = "${aerothemeplasma-git}/plasma/shells";
    ".local/share/kwin/effects".source = "${aerothemeplasma-git}/kwin/effects";
    ".local/share/kwin/tabbox".source = "${aerothemeplasma-git}/kwin/tabbox";
    ".local/share/kwin/outline".source = "${aerothemeplasma-git}/kwin/outline";
    ".config/fontconfig/fonts.conf".source = "${aerothemeplasma-git}/misc/fontconfig/fonts.conf";
    ".local/share/smod".source = "${aerothemeplasma-git}/plasma/smod";
    ".local/share/sddm/themes/sddm-theme-mod".source = "${aerothemeplasma-git}/plasma/sddm/sddm-theme-mod";
  };
  programs.plasma = {
    enable = true;
    shortcuts.kwin = {
      "MinimizeAll" = "Meta+D";
      "Peek at Desktop" = [];
      "Walk Through Windows Alternative" = "Meta+Tab";
    };
    configFile = {
      "kwinrc"."TabBox" = {
        "LayoutName" = "thumbnail_seven";
        "ShowDesktopMode" = 1;
      };
      "kwinrc"."TabBoxAlternative" = {
        "LayoutName" = "flipswitch";
      };
      "kwinrc"."MouseBindings"."CommandWheel" = "Nothing";
      "kwinrc"."Plugins" = {
        "kwin4_effect_aeroglassblurEnabled" = true;
        "kwin4_effect_aeroglideEnabled" = true;
        "smodsnapEnabled" = true;
        "smodglowEnabled" = true;
        "startupfeedbackEnabled" = true;
        "desaturateUnresponsiveAppsEnabled" = true;
        "fadingPopupsEnabled" = true;
        "loginEnabled" = true;
        "squashEnabled" = true;
        "smodpeekeffectEnabled" = true;
        "dimScreenForAdminModeEnabled" = true;
        "minimizeallEnabled" = true;
        "dimscreenEnabled" = true;
        "backgroundcontrastEnabled" = false;
        "blurEnabled" = false;
        "maximizeEnabled" = false;
        "slidingpopupsEnabled" = false;
        "dialogparentEnabled" = false;
        "diminactiveEnabled" = false;
        "logoutEnabled" = false;
      };
      "kwinrc"."Scripts" = {
        "minimizeall" = true;
        "smodpeekscript" = true;
      };
      "ksmserverrc"."General"."confirmLogout" = false;
      "kwinrc"."org.kde.kdecoration2"."BorderSize" = "Normal";
      "kwinrc"."org.kde.kdecoration2"."theme" = "SMOD";
      "kwinrc"."org.kde.kdecoration3"."library" = "org.smod.smod";
      "kwinrc"."org.kde.kdecoration3"."theme" = "aerotheme";
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='C:''${PWD//\//\\\\}> '
      echo -e "Microsoft Windows [Version 6.1.7600]\nCopyright (c) 2009 Microsoft Corporation. All rights reserved.\n"
    '';
  };
}
