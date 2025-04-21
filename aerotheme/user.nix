{
  config,
  pkgs,
  lib,
  ...
}: let
  aerothemeplasmaPkgs = pkgs.callPackage ./aerothemeplasma.nix {inherit pkgs;};
  inherit (aerothemeplasmaPkgs) aerothemeplasma;
in {
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
      "kwinrc"."org.kde.kdecoration3" = {
        "library" = "org.smod.smod";
        "theme" = "aerotheme";
      };
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
