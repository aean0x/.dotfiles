{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasmaPkgs = pkgs.callPackage ./aerothemeplasma.nix {inherit pkgs;};
  inherit (aerothemeplasmaPkgs) aerothemeplasma aerothemeplasma-git;
in {
  home.sessionVariables = {
    QT_PLUGIN_PATH = "${aerothemeplasma}/lib/qt-6/plugins:$QT_PLUGIN_PATH";
    QML2_IMPORT_PATH = "${aerothemeplasma}/lib/qt-6/qml:$QML2_IMPORT_PATH";
    QML_DISABLE_DISTANCEFIELD = "1";
  };

  home.file = {
    ".local/share/plasma/desktoptheme".source = "${aerothemeplasma-git}/plasma/desktoptheme";
    ".local/share/plasma/look-and-feel".source = "${aerothemeplasma-git}/plasma/look-and-feel";
    ".local/share/plasma/plasmoids".source = "${aerothemeplasma-git}/plasma/plasmoids";
    ".local/share/plasma/layout-templates".source = "${aerothemeplasma-git}/plasma/layout-templates";
    ".local/share/plasma/shells".source = "${aerothemeplasma-git}/plasma/shells";
    ".local/share/kwin/effects".source = "${aerothemeplasma-git}/kwin/effects";
    ".local/share/kwin/tabbox".source = "${aerothemeplasma-git}/kwin/tabbox";
    ".local/share/kwin/outline".source = "${aerothemeplasma-git}/kwin/outline";
    ".local/share/kwin/scripts".source = "${aerothemeplasma-git}/kwin/scripts";
    ".local/share/color-schemes".source = "${aerothemeplasma-git}/plasma/color_scheme";
    ".config/Kvantum".source = "${aerothemeplasma-git}/misc/kvantum/Kvantum";
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
      "kcminputrc"."Mouse" = {
        "cursorTheme" = "aero-drop";
        "BusyCursor" = "none";
      };
      "kdeglobals"."General" = {
        "font" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        "fixed" = "Hack,10,-1,5,50,0,0,0,0,0";
        "menuFont" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        "toolBarFont" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        "smallestReadableFont" = "Segoe UI,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
        "XftAntialias" = true;
        "XftHintStyle" = "hintslight";
        "accentColorFromWallpaper" = false;
        "ColorScheme" = "AeroColorScheme1";
        "ShowDeleteCommand" = false;
      };
      "kdeglobals"."Icons"."Theme" = "Windows 7 Aero";
      "kdeglobals"."Sounds"."Theme" = "Windows 7";
      "kdeglobals"."KDE"."LookAndFeelPackage" = "AeroThemePlasma";
      "kdeglobals"."WM"."activeFont" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
      "kwinrc"."Windows" = {
        "RollOverTitlebar" = "None";
        "BorderSnapZone" = 15;
        "WindowSnapZone" = 15;
      };
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
      "kwinrc"."org.kde.kdecoration2" = {
        "library" = "org.smod.smod";
        "theme" = "aerotheme";
      };
      "ksmserverrc"."General"."confirmLogout" = false;
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
