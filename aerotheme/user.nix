{
  config,
  pkgs,
  lib,
  ...
}: {
  home.file = {
    # TODO: find a better way to do this than home symlinks.
    ".local/share/plasma/desktoptheme".source = "${pkgs.aerothemeplasma-git}/plasma/desktoptheme";
    ".local/share/plasma/look-and-feel".source = "${pkgs.aerothemeplasma-git}/plasma/look-and-feel";
    ".local/share/plasma/plasmoids".source = "${pkgs.aerothemeplasma-git}/plasma/plasmoids";
    ".local/share/plasma/layout-templates".source = "${pkgs.aerothemeplasma-git}/plasma/layout-templates";
    ".local/share/plasma/shells".source = "${pkgs.aerothemeplasma-git}/plasma/shells";
    ".local/share/kwin/effects".source = "${pkgs.aerothemeplasma-git}/kwin/effects";
    ".local/share/kwin/tabbox".source = "${pkgs.aerothemeplasma-git}/kwin/tabbox";
    ".local/share/kwin/outline".source = "${pkgs.aerothemeplasma-git}/kwin/outline";
    # ".config/fontconfig/fonts.conf".source = "${pkgs.aerothemeplasma-git}/misc/fontconfig/fonts.conf";
    ".local/share/smod".source = "${pkgs.aerothemeplasma-git}/plasma/smod";
    ".local/share/sddm/themes/sddm-theme-mod".source = "${pkgs.aerothemeplasma-git}/plasma/sddm/sddm-theme-mod";
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
      "kcminputrc"."Mouse"."BusyCursor" = "none";
      "klaunchrc"."FeedbackStyle"."BusyCursor" = false;
      "kdeglobals"."General"."XftAntialias" = true;
      "kdeglobals"."General"."XftHintStyle" = "hintslight";
      "kdeglobals"."General"."XftSubPixel" = "rgb";
      "kdeglobals"."General" = {
        "font" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        "menuFont" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        "toolBarFont" = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        "smallestReadableFont" = "Segoe UI,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      };
      "kdeglobals"."General"."accentColorFromWallpaper" = false;
    };
  };

  # programs.bash = {
  #   enable = true;
  #   initExtra = ''
  #     PS1='C:''${PWD//\//\\\\}> '
  #     echo -e "Microsoft Windows [Version 6.1.7600]\nCopyright (c) 2009 Microsoft Corporation. All rights reserved.\n"
  #   '';
  # };
}
