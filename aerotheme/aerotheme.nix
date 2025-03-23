{
  config,
  lib,
  pkgs,
  ...
}: let
  aerothemeplasma = pkgs.callPackage ./aerothemeplasma.nix {};
  repoDir = "${aerothemeplasma}/share/aerothemeplasma/source";
  buildDir = "$HOME/.cache/aerothemeplasma-build/output";
in {
  home.activation = {
    buildAeroThemePlasma = lib.hm.dag.entryBefore ["installAeroThemePlasma"] ''
      PATH="${lib.makeBinPath [pkgs.git pkgs.docker pkgs.coreutils]}:$PATH"
      echo "Building AeroThemePlasma..."
      ${aerothemeplasma}/bin/build-aerotheme
    '';
    installAeroThemePlasma = lib.hm.dag.entryAfter ["writeBoundary" "buildAeroThemePlasma"] ''
      PATH="${lib.makeBinPath [pkgs.coreutils pkgs.shared-mime-info]}:$PATH"
      echo "Installing compiled AeroThemePlasma components..."
      for dir in qml/org/kde/plasma/core plugins/org.kde.kdecoration3 plugins/kwin/effects/plugins plugins/kwin/effects/configs; do
        target_dir="$HOME/.local/lib/qt6/$dir"
        mkdir -p "$target_dir"
        [ -d "${buildDir}/lib/qt6/$dir" ] && cp -rf "${buildDir}/lib/qt6/$dir/." "$target_dir/"
        chmod -R u+rwX "$target_dir" 2>/dev/null || true
      done
      if [ -d "$HOME/.local/share/mime/packages" ]; then
        update-mime-database "$HOME/.local/share/mime" || true
        chmod -R u+rwX "$HOME/.local/share/mime" 2>/dev/null || true
      fi
      for dir in ".local/share/smod" ".local/share/plasma" ".local/share/kwin" ".config/Kvantum" ".local/share/mime/packages" ".config/kdedefaults"; do
        [ -d "$HOME/$dir" ] && chmod -R u+rwX "$HOME/$dir" 2>/dev/null || true
      done
    '';
  };

  home.file = {
    ".local/share/smod".source = "${repoDir}/plasma/smod";
    ".local/share/plasma/desktoptheme".source = "${repoDir}/plasma/desktoptheme";
    ".local/share/plasma/look-and-feel".source = "${repoDir}/plasma/look-and-feel";
    ".local/share/plasma/plasmoids".source = "${repoDir}/plasma/plasmoids";
    ".local/share/plasma/layout-templates".source = "${repoDir}/plasma/layout-templates";
    ".local/share/plasma/shells".source = "${repoDir}/plasma/shells";
    ".local/share/color-schemes".source = "${repoDir}/plasma/color_scheme";
    ".local/share/kwin/effects".source = "${repoDir}/kwin/effects";
    ".local/share/kwin/tabbox".source = "${repoDir}/kwin/tabbox";
    ".local/share/kwin/outline".source = "${repoDir}/kwin/outline";
    ".local/share/kwin/scripts".source = "${repoDir}/kwin/scripts";
    ".config/Kvantum".source = "${repoDir}/misc/kvantum/Kvantum";
    ".local/share/mime/packages".source = "${repoDir}/misc/mimetype";
    ".config/kdedefaults/kcm-about-distrorc".source = "${repoDir}/misc/branding/kcm-about-distrorc";
    ".config/kdedefaults/kcminfo.png".source = "${repoDir}/misc/branding/kcminfo.png";
    ".local/share/icons".source = "${aerothemeplasma}/share/aerothemeplasma/icons";
    ".local/share/sounds".source = "${aerothemeplasma}/share/aerothemeplasma/sounds";
  };

  home.sessionVariables = {
    QML_DISABLE_DISTANCEFIELD = "1";
    QT_PLUGIN_PATH = "$HOME/.local/lib/qt6/plugins:${aerothemeplasma}/lib/qt6/plugins";
    QML2_IMPORT_PATH = "$HOME/.local/lib/qt6/qml:${aerothemeplasma}/lib/qt6/qml";
  };

  programs.plasma = {
    enable = true;
    shortcuts.kwin = {
      "MinimizeAll" = "Meta+D";
      "Peek at Desktop" = "";
      "Walk Through Windows Alternative" = "Meta+Tab";
    };
    configFile = {
      "kcminputrc"."Mouse".cursorTheme = "aero-drop";
      "kdeglobals"."General" = {
        font = "Segoe UI,9,-1,5,50,0,0,0,0,0";
        fixed = "Consolas,9,-1,5,50,0,0,0,0,0";
        "XftAntialias" = true;
        "XftHintStyle" = "hintslight";
        "accentColorFromWallpaper" = false;
        "ShowDeleteCommand" = false;
      };
      "kdeglobals"."Sounds"."Theme" = "Windows 7";
      "kwinrc"."Windows" = {
        "RollOverTitlebar" = "None";
        "BorderSnapZone" = 15;
        "WindowSnapZone" = 15;
      };
      "kwinrc"."TabBox" = {
        "LayoutName" = "thumbnail_seven";
        "ShowDesktopMode" = 1;
      };
      "kwinrc"."TabBoxAlternative"."LayoutName" = "flipswitch";
      "kwinrc"."Plugins" = {
        "blurEnabled" = false;
        "contrastEnabled" = false;
        "maximizeEnabled" = false;
        "slidingpopupsEnabled" = false;
        "dialogparentEnabled" = false;
        "diminactiveEnabled" = false;
        "logoutEnabled" = false;
        "smodpeekeffectEnabled" = true;
        "minimizeallEnabled" = true;
        "dimscreenEnabled" = true;
      };
      "kwinrc"."Scripts" = {
        "minimizeall" = true;
        "smodpeekscript" = true;
      };
      "ksmserver"."General"."confirmLogout" = false;
      "kwinrc"."Mouse"."BusyCursor" = "none";
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='C:''${PWD//\//\\\\}> '
      echo -e "Microsoft Windows [Version 6.1.7600]\nCopyright (c) 2009 Microsoft Corporation. All rights reserved.\n"
    '';
  };

  xdg.configFile."fontconfig/fonts.conf".source = "${repoDir}/misc/fontconfig/fonts.conf";
}
