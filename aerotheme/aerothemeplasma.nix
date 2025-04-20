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

  # Expose the source repo directly
  aerothemeplasma-git = themeRepo;

  # Common native build inputs
  commonNativeBuildInputs = [
    cmake
    ninja
    pkgs.kdePackages.extra-cmake-modules
    pkgs.kdePackages.wrapQtAppsHook
    pkgs.kdePackages.qttools.dev
    makeWrapper
  ];

  # Common Qt6 dependencies
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

  # Common KF6 dependencies
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
  ];

  # Common development packages
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

  # Common Plasma/KWin dependencies
  plasmaDeps = with pkgs.kdePackages; [
    plasma5support
    plasma-wayland-protocols
    kwin
    kwin.dev
    kirigami
  ];

  # Common X11/OpenGL dependencies
  x11Deps = with pkgs; [
    libepoxy
    xorg.libX11
    xorg.xcbutil
  ];

  # Define separate derivations for each component
  decoration = stdenv.mkDerivation {
    name = "aerotheme-decoration";
    src = "${themeRepo}/kwin/decoration";
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [pkgs.kdePackages.libplasma];
    cmakeFlags = [
      "-DBUILD_QT6=ON"
      "-DCMAKE_INCLUDE_PATH=${pkgs.kdePackages.kwin.dev}/include/kwin"
    ];
    installPhase = ''
      mkdir -p $out/lib/qt-6/plugins/org.kde.kdecoration3
      mkdir -p $out/lib/qt-6/plugins/org.kde.kdecoration3.kcm
      ninja install
    '';
  };

  commonCmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_KF6=ON"
    "-DKWIN_INCLUDE=${pkgs.kdePackages.kwin.dev}/include/kwin"
    "-DKPLUGINFACTORY_INCLUDE=${pkgs.kdePackages.kcoreaddons.dev}/include/KF6/KCoreAddons"
    ''-DCMAKE_CXX_FLAGS="-I${pkgs.kdePackages.kwin.dev}/include/kwin -I${pkgs.kdePackages.kcoreaddons.dev}/include/KF6/KCoreAddons"''
    "-DKWin_DIR=${pkgs.kdePackages.kwin.dev}/lib/cmake/KWin"
    "-DKDE_INSTALL_PLUGINDIR=lib/qt-6/plugins"
  ];

  smodsnap = stdenv.mkDerivation {
    name = "aerotheme-smodsnap";
    src = "${themeRepo}/kwin/effects_cpp/kwin-effect-smodsnap-v2";
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build-kf6 -G Ninja -DCMAKE_INSTALL_PREFIX=$out ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build-kf6
    '';
    installPhase = ''
      ninja install -C build-kf6
      # Ensure the plugin is in the correct directory
      mkdir -p $out/lib/qt-6/plugins/kwin/effects/plugins
      mv $out/lib/plugins/kwin/effects/plugins/* $out/lib/qt-6/plugins/kwin/effects/plugins/ || true
    '';
  };

  smodglow = stdenv.mkDerivation {
    name = "aerotheme-smodglow";
    src = "${themeRepo}/kwin/effects_cpp/smodglow";
    nativeBuildInputs = commonNativeBuildInputs ++ [pkgs.pkg-config];
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build-kf6 -G Ninja -DCMAKE_INSTALL_PREFIX=$out ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build-kf6
    '';
    installPhase = ''
      ninja install -C build-kf6
      mkdir -p $out/lib/qt-6/plugins/kwin/effects/plugins
      mv $out/lib/plugins/kwin/effects/plugins/* $out/lib/qt-6/plugins/kwin/effects/plugins/ || true
    '';
  };

  startupfeedback = stdenv.mkDerivation {
    name = "aerotheme-startupfeedback";
    src = "${themeRepo}/kwin/effects_cpp/startupfeedback";
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build-kf6 -G Ninja -DCMAKE_INSTALL_PREFIX=$out ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build-kf6
    '';
    installPhase = ''
      ninja install -C build-kf6
      mkdir -p $out/lib/qt-6/plugins/kwin/effects/plugins
      mv $out/lib/plugins/kwin/effects/plugins/* $out/lib/qt-6/plugins/kwin/effects/plugins/ || true
    '';
  };

  aeroglassblur = stdenv.mkDerivation {
    name = "aerotheme-aeroglassblur";
    src = "${themeRepo}/kwin/effects_cpp/kde-effects-aeroglassblur";
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build-kf6 -G Ninja -DCMAKE_INSTALL_PREFIX=$out ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build-kf6
    '';
    installPhase = ''
      ninja install -C build-kf6
      mkdir -p $out/lib/qt-6/plugins/kwin/effects/plugins
      mv $out/lib/plugins/kwin/effects/plugins/* $out/lib/qt-6/plugins/kwin/effects/plugins/ || true
    '';
  };

  aeroglide = stdenv.mkDerivation {
    name = "aerotheme-aeroglide";
    src = "${themeRepo}/kwin/effects_cpp/aeroglide";
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ kf6DevDeps ++ plasmaDeps ++ x11Deps ++ [decoration];
    configurePhase = ''
      cmake -B build-kf6 -G Ninja -DCMAKE_INSTALL_PREFIX=$out ${lib.concatStringsSep " " commonCmakeFlags}
    '';
    buildPhase = ''
      ninja -C build-kf6
    '';
    installPhase = ''
      ninja install -C build-kf6
      mkdir -p $out/lib/qt-6/plugins/kwin/effects/plugins
      mv $out/lib/plugins/kwin/effects/plugins/* $out/lib/qt-6/plugins/kwin/effects/plugins/ || true
    '';
  };

  corebindingsplugin = stdenv.mkDerivation {
    name = "aerotheme-corebindingsplugin";
    src = pkgs.kdePackages.libplasma.src;
    nativeBuildInputs = commonNativeBuildInputs;
    buildInputs = qt6Deps ++ kf6Deps ++ [ pkgs.kdePackages.plasma-wayland-protocols ];
    postUnpack = ''
      cp ${themeRepo}/misc/defaulttooltip/DefaultToolTip.qml $sourceRoot/src/declarativeimports/core/private/
    '';
    configurePhase = ''
      cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    '';
    buildPhase = ''
      ninja -C build corebindingsplugin
    '';
    installPhase = ''
      pluginPath=$(find build -name libcorebindingsplugin.so)
      mkdir -p $out/lib/qt6/qml/org/kde/plasma/core
      cp $pluginPath $out/lib/qt6/qml/org/kde/plasma/core/
    '';
  };

  aerothemeplasma = stdenv.mkDerivation {
    name = "aerothemeplasma";
    src = themeRepo;
    nativeBuildInputs = [gnutar];
    installPhase = ''
      # Create necessary directories
      mkdir -p $out/share/plasma/desktoptheme \
        $out/share/plasma/look-and-feel \
        $out/share/plasma/plasmoids \
        $out/share/plasma/layout-templates \
        $out/share/plasma/shells \
        $out/share/kwin/effects \
        $out/share/kwin/tabbox \
        $out/share/kwin/outline \
        $out/share/kwin/scripts \
        $out/share/color-schemes \
        $out/share/Kvantum \
        $out/share/sddm/themes \
        $out/share/mime/packages \
        $out/share/icons/Windows\ 7\ Aero \
        $out/share/sounds/Windows\ 7 \
        $out/share/icons

      # Copy Plasma components
      [ -d "$src/plasma/desktoptheme" ] && cp -r "$src/plasma/desktoptheme"/* $out/share/plasma/desktoptheme/
      [ -d "$src/plasma/look-and-feel" ] && cp -r "$src/plasma/look-and-feel"/* $out/share/plasma/look-and-feel/
      [ -d "$src/plasma/plasmoids" ] && cp -r "$src/plasma/plasmoids"/* $out/share/plasma/plasmoids/
      [ -d "$src/plasma/layout-templates" ] && cp -r "$src/plasma/layout-templates"/* $out/share/plasma/layout-templates/
      [ -d "$src/plasma/shells" ] && cp -r "$src/plasma/shells"/* $out/share/plasma/shells/
      [ -d "$src/kwin/effects" ] && cp -r "$src/kwin/effects"/* $out/share/kwin/effects/
      [ -d "$src/kwin/tabbox" ] && cp -r "$src/kwin/tabbox"/* $out/share/kwin/tabbox/
      [ -d "$src/kwin/outline" ] && cp -r "$src/kwin/outline"/* $out/share/kwin/outline/
      [ -d "$src/kwin/scripts" ] && cp -r "$src/kwin/scripts"/* $out/share/kwin/scripts/
      [ -d "$src/plasma/color_scheme" ] && cp -r "$src/plasma/color_scheme"/* $out/share/color-schemes/
      [ -d "$src/misc/kvantum/Kvantum" ] && cp -r "$src/misc/kvantum/Kvantum"/* $out/share/Kvantum/

      # Existing installations (SDDM, MIME, icons, sounds)
      [ -d "$src/plasma/smod" ] && cp -r "$src/plasma/smod" $out/share/smod
      [ -d "$src/plasma/sddm/sddm-theme-mod" ] && cp -r "$src/plasma/sddm/sddm-theme-mod" $out/share/sddm/themes/
      [ -d "$src/misc/mimetype" ] && cp -r "$src/misc/mimetype"/* $out/share/mime/packages/
      [ -f "$src/misc/cursors/aero-drop.tar.gz" ] && tar -xzf "$src/misc/cursors/aero-drop.tar.gz" -C $out/share/icons
      [ -f "$src/misc/icons/Windows 7 Aero.tar.gz" ] && tar -xzf "$src/misc/icons/Windows 7 Aero.tar.gz" -C $out/share/icons/Windows\ 7\ Aero
      [ -f "$src/misc/sounds/sounds.tar.gz" ] && tar -xzf "$src/misc/sounds/sounds.tar.gz" -C $out/share/sounds/Windows\ 7
    '';
    meta = {
      description = "Windows 7 theme for KDE Plasma";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.linux;
    };
  };
in {
  inherit decoration smodsnap smodglow startupfeedback aeroglassblur aeroglide aerothemeplasma aerothemeplasma-git;
}
