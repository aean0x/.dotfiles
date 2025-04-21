{
  stdenv,
  lib,
  fetchzip,
  cmake,
  ninja,
  qt6,
  pkgs,
  makeWrapper,
  gnutar,
}: let
  themeRepo = fetchzip {
    url = "https://gitgud.io/wackyideas/aerothemeplasma/-/archive/master/aerothemeplasma-master.zip";
    sha256 = "sha256-vnYi1uV3HUAAyZhPMPazI/1V6x88QoknKNBiMiVBGYA=";
  };

  aerothemeplasma-git = themeRepo;

  commonNativeBuildInputs = [
    cmake
    ninja
    pkgs.kdePackages.extra-cmake-modules
    pkgs.kdePackages.wrapQtAppsHook
    pkgs.kdePackages.qttools.dev
    makeWrapper
  ];

  qt6Deps = with pkgs.kdePackages; [
    qtbase
    qtwayland
    qtsvg
    qtmultimedia
    qt5compat
    qtvirtualkeyboard
    qtdeclarative
    qttools
    pkgs.qt6.qtbase.dev
  ];

  kf6Deps = with pkgs.kdePackages; [
    karchive
    kwindowsystem
    kconfig
    kconfigwidgets
    kcoreaddons
    kguiaddons
    kiconthemes
    ki18n
    knotifications
    kio
    kauth
    kdecoration
    kcrash
    kglobalaccel
    kservice
    kwidgetsaddons
    kcompletion
    kxmlgui
    ksvg
    kcmutils
    kpackage
  ];

  kf6DevDeps = with pkgs.kdePackages; [
    kconfig.dev
    kcoreaddons.dev
    kwindowsystem.dev
    kdecoration.dev
    ki18n.dev
    kauth.dev
    kcrash.dev
    kglobalaccel.dev
    knotifications.dev
    kio.dev
    kservice.dev
    kcmutils.dev
    kxmlgui.dev
    kiconthemes.dev
  ];

  plasmaDeps = with pkgs.kdePackages; [
    plasma5support
    plasma-wayland-protocols
    kwin
    kwin.dev
    kirigami
    plasma-activities
  ];

  x11Deps = with pkgs; [
    libepoxy
    xorg.libX11
    xorg.xcbutil
  ];

  commonCmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_KF6=ON"
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DKDE_INSTALL_PLUGINDIR=lib/qt-6/plugins" # it's qt-6 on Nix for some reason
    "-DKDE_INSTALL_QMLDIR=lib/qt-6/qml" # no idea why
    "-DKWIN_INCLUDE=${pkgs.kdePackages.kwin.dev}/include/kwin"
    "-DKPLUGINFACTORY_INCLUDE=${pkgs.kdePackages.kcoreaddons.dev}/include/KF6/KCoreAddons"
    ''-DCMAKE_CXX_FLAGS="-I${pkgs.kdePackages.kwin.dev}/include/kwin -I${pkgs.kdePackages.kcoreaddons.dev}/include/KF6/KCoreAddons"''
    "-DKWin_DIR=${pkgs.kdePackages.kwin.dev}/lib/cmake/KWin"
  ];

  decoration = stdenv.mkDerivation {
    name = "aerotheme-decoration";
    src = "${themeRepo}/kwin/decoration";
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [pkgs.kdePackages.libplasma];
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  smodsnap = stdenv.mkDerivation {
    name = "aerotheme-smodsnap";
    src = "${themeRepo}/kwin/effects_cpp/kwin-effect-smodsnap-v2";
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  smodglow = stdenv.mkDerivation {
    name = "aerotheme-smodglow";
    src = "${themeRepo}/kwin/effects_cpp/smodglow";
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  startupfeedback = stdenv.mkDerivation {
    name = "aerotheme-startupfeedback";
    src = "${themeRepo}/kwin/effects_cpp/startupfeedback";
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  aeroglassblur = stdenv.mkDerivation {
    name = "aerotheme-aeroglassblur";
    src = "${themeRepo}/kwin/effects_cpp/kde-effects-aeroglassblur";
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  aeroglide = stdenv.mkDerivation {
    name = "aerotheme-aeroglide";
    src = "${themeRepo}/kwin/effects_cpp/aeroglide";
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  corebindingsplugin = stdenv.mkDerivation {
    name = "aerotheme-corebindingsplugin";
    src = pkgs.kdePackages.libplasma.src;
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ [pkgs.wayland];
    postunpack = ''
      cp ${themeRepo}/misc/defaulttooltip/defaulttooltip.qml $sourceroot/src/declarativeimports/core/private/
    '';
    configurePhase = ''
      cmake -B build -G Ninja ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build corebindingsplugin
    '';
    installPhase = ''
      ninja install -C build
    '';
  };

  aerothemeplasma = stdenv.mkDerivation {
    name = "aerothemeplasma";
    src = themeRepo;
    nativeBuildInputs = [gnutar];
    installPhase = ''
      mkdir -p $out/share/plasma/desktoptheme \
        $out/share/plasma/look-and-feel \
        $out/share/plasma/plasmoids \
        $out/share/plasma/layout-templates \
        $out/share/plasma/shells \
        $out/share/kwin/effects \
        $out/share/kwin/tabbox \
        $out/share/kwin/outline \
        $out/share/plasma/desktoptheme/aerotheme/outline \
        $out/share/kwin/scripts \
        $out/share/color-schemes \
        $out/share/Kvantum \
        $out/share/sddm/themes \
        $out/share/mime/packages \
        $out/share/icons/Windows\ 7\ Aero \
        $out/share/sounds/Windows\ 7 \
        $out/share/icons

      [ -d "$src/plasma/desktoptheme" ] && cp -r "$src/plasma/desktoptheme"/* $out/share/plasma/desktoptheme/
      [ -d "$src/plasma/look-and-feel" ] && cp -r "$src/plasma/look-and-feel"/* $out/share/plasma/look-and-feel/
      [ -d "$src/plasma/plasmoids" ] && cp -r "$src/plasma/plasmoids"/* $out/share/plasma/plasmoids/
      [ -d "$src/plasma/layout-templates" ] && cp -r "$src/plasma/layout-templates"/* $out/share/plasma/layout-templates/
      [ -d "$src/plasma/shells" ] && cp -r "$src/plasma/shells"/* $out/share/plasma/shells/
      [ -d "$src/kwin/effects" ] && cp -r "$src/kwin/effects"/* $out/share/kwin/effects/
      [ -d "$src/kwin/tabbox" ] && cp -r "$src/kwin/tabbox"/* $out/share/kwin/tabbox/
      [ -d "$src/kwin/outline" ] && cp -r "$src/kwin/outline"/* $out/share/plasma/desktoptheme/aerotheme/outline/
      [ -d "$src/kwin/scripts" ] && cp -r "$src/kwin/scripts"/* $out/share/kwin/scripts/
      [ -d "$src/plasma/color_scheme" ] && cp -r "$src/plasma/color_scheme"/* $out/share/color-schemes/
      [ -d "$src/misc/kvantum/Kvantum" ] && cp -r "$src/misc/kvantum/Kvantum"/* $out/share/Kvantum/
      [ -d "$src/plasma/smod" ] && cp -r "$src/plasma/smod" $out/share/smod
      [ -d "$src/plasma/sddm/sddm-theme-mod" ] && cp -r "$src/plasma/sddm/sddm-theme-mod" $out/share/sddm/themes/
      [ -d "$src/misc/mimetype" ] && cp -r "$src/misc/mimetype"/* $out/share/mime/packages/
      [ -f "$src/misc/cursors/aero-drop.tar.gz" ] && tar -xzf "$src/misc/cursors/aero-drop.tar.gz" -C $out/share/icons
      [ -f "$src/misc/icons/Windows 7 Aero.tar.gz" ] && tar -xzf "$src/misc/icons/Windows 7 Aero.tar.gz" -C $out/share/icons/Windows\ 7\ Aero
      [ -f "$src/misc/sounds/sounds.tar.gz" ] && tar -xzf "$src/misc/sounds/sounds.tar.gz" -C $out/share/sounds
    '';
    meta = {
      description = "Windows 7 theme for KDE Plasma";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.linux;
    };
  };
in {
  inherit decoration smodsnap smodglow startupfeedback aeroglassblur aeroglide aerothemeplasma aerothemeplasma-git corebindingsplugin;
}
