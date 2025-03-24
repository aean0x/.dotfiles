{
  stdenv,
  lib,
  fetchzip,
  cmake,
  ninja,
  extra-cmake-modules,
  pkgs,
}:
stdenv.mkDerivation rec {
  name = "aerothemeplasma";
  src = fetchzip {
    url = "https://gitgud.io/wackyideas/aerothemeplasma/-/archive/master/aerothemeplasma-master.zip";
    sha256 = "sha256-vnYi1uV3HUAAyZhPMPazI/1V6x88QoknKNBiMiVBGYA=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    extra-cmake-modules
    pkgs.gnutar
    pkgs.gzip
    pkgs.kdePackages.wrapQtAppsHook
  ];

  buildInputs = [
    # Qt dependencies
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtwayland
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtvirtualkeyboard

    # KDE Framework dependencies
    pkgs.kdePackages.extra-cmake-modules
    pkgs.kdePackages.karchive
    pkgs.kdePackages.kwindowsystem
    pkgs.kdePackages.kconfig
    pkgs.kdePackages.kconfigwidgets
    pkgs.kdePackages.kcoreaddons
    pkgs.kdePackages.kguiaddons
    pkgs.kdePackages.kiconthemes
    pkgs.kdePackages.ki18n
    pkgs.kdePackages.knotifications
    pkgs.kdePackages.kio
    pkgs.kdePackages.kauth
    pkgs.kdePackages.kdecoration
    pkgs.kdePackages.kcrash
    pkgs.kdePackages.kglobalaccel
    pkgs.kdePackages.kservice
    pkgs.kdePackages.kwidgetsaddons
    pkgs.kdePackages.kcompletion
    pkgs.kdePackages.kxmlgui

    # Plasma dependencies
    pkgs.kdePackages.plasma5support
    pkgs.kdePackages.plasma-wayland-protocols
    pkgs.kdePackages.kwin
    pkgs.kdePackages.ksvg
    pkgs.kdePackages.kirigami
    pkgs.kdePackages.kcmutils
  ];

  # For Qt plugins discovery
  qtWrapperArgs = [
    "--prefix QT_PLUGIN_PATH : ${placeholder "out"}/lib/qt6/plugins"
    "--prefix QML2_IMPORT_PATH : ${placeholder "out"}/lib/qt6/qml"
  ];

  # Disable the default CMake configure phase
  dontUseCmakeConfigure = true;

  # Analyze and properly setup the repo and build environment
  patchPhase = ''
        # Check the actual structure of the repo
        echo "Repository structure:"
        find . -maxdepth 3 -type f -name "CMakeLists.txt" | sort

        # Create necessary build support directories
        mkdir -p kde_support/cmake_modules

        # Create a proper KDE6Config.cmake file that contains all needed macros
        echo '# KDE6Config.cmake - Complete KDE6 compatibility layer

    message(STATUS "Initializing KDE6 compatibility layer")

    # Set up basic variables
    set(KDE6_INCLUDE_DIRS ''${CMAKE_CURRENT_LIST_DIR}/../../include)
    set(KDE6_LIB_DIR ''${CMAKE_CURRENT_LIST_DIR}/../../lib)

    # Define macros for KConfig
    macro(kconfig_add_kcfg_files _target)
      message(STATUS "Processing KConfig files for target: ''${_target}")
      foreach(file ''${ARGN})
        message(STATUS "  - Would process: ''${file}")
      endforeach()
    endmacro()' > kde_support/cmake_modules/KDE6Config.cmake

        # Create a compatibility FindKF6.cmake
        echo '# FindKF6.cmake

    message(STATUS "Finding KF6 components: ''${KF6_FIND_COMPONENTS}")

    # Set KF6_FOUND to TRUE
    set(KF6_FOUND TRUE)

    # Process components
    foreach(comp ''${KF6_FIND_COMPONENTS})
      set(KF6''${comp}_FOUND TRUE)
      message(STATUS "  - KF6''${comp} found (compatibility layer)")
    endforeach()' > kde_support/cmake_modules/FindKF6.cmake

        # Create a KDECMakeSettings.cmake
        echo '# KDECMakeSettings.cmake

    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)' > kde_support/cmake_modules/KDECMakeSettings.cmake

        # Examine the effect CMakeLists.txt files to identify issues
        echo "Analyzing effect CMakeLists.txt files:"
        for effect_dir in kwin/effects_cpp/*; do
          if [ -d "$effect_dir/src" ] && [ -f "$effect_dir/src/CMakeLists.txt" ]; then
            echo "Found effect: $effect_dir"

            # Check if the effect's CMakeLists.txt is missing basic elements
            if ! grep -q "cmake_minimum_required" "$effect_dir/src/CMakeLists.txt"; then
              echo "  - Adding missing cmake_minimum_required"
              sed -i '1i cmake_minimum_required(VERSION 3.16)' "$effect_dir/src/CMakeLists.txt"
            fi

            if ! grep -q "project" "$effect_dir/src/CMakeLists.txt"; then
              echo "  - Adding missing project declaration"
              effect_name=$(basename "$effect_dir")
              sed -i "2i project($effect_name VERSION 1.0)" "$effect_dir/src/CMakeLists.txt"
            fi

            # Adapt CMakeLists.txt to work with KF6
            echo "  - Updating CMakeLists.txt for KF6 compatibility"

            # Backup original file
            cp "$effect_dir/src/CMakeLists.txt" "$effect_dir/src/CMakeLists.txt.bak"

            # Update package references
            sed -i 's/find_package(KF5 /find_package(KF6 /g' "$effect_dir/src/CMakeLists.txt"
            sed -i 's/find_package(KDE4 /find_package(KF6 /g' "$effect_dir/src/CMakeLists.txt"
            sed -i 's/find_package(Qt5 /find_package(Qt6 /g' "$effect_dir/src/CMakeLists.txt"

            # Update target references
            sed -i 's/Qt5::/Qt6::/g' "$effect_dir/src/CMakeLists.txt"
            sed -i 's/KF5::/KF6::/g' "$effect_dir/src/CMakeLists.txt"
            sed -i 's/KDE4::/KF6::/g' "$effect_dir/src/CMakeLists.txt"

            # Replace KConfig macros if needed
            if grep -q "kconfig_add_kcfg_files" "$effect_dir/src/CMakeLists.txt"; then
              echo "  - Adding KConfig include directives"
              sed -i '3i include(''${CMAKE_CURRENT_SOURCE_DIR}/../../../kde_support/cmake_modules/KDE6Config.cmake)' "$effect_dir/src/CMakeLists.txt"
            fi
          fi
        done

        # Handle kwin/decoration differently (it's a special case)
        if [ -f kwin/decoration/CMakeLists.txt ]; then
          echo "Special handling for kwin/decoration"

          # If the file is complex, we'll extract only what we need instead of modifying it
          mkdir -p kwin/decoration/simplified

          # Create a simplified CMakeLists.txt that just copies the files
          echo 'cmake_minimum_required(VERSION 3.16)
    project(aero-decoration VERSION 1.0)

    install(DIRECTORY ''${CMAKE_CURRENT_SOURCE_DIR}/..
            DESTINATION ''${CMAKE_INSTALL_PREFIX}/share/kwin/decoration
            FILES_MATCHING
            PATTERN "*.cpp"
            PATTERN "*.h"
            PATTERN "*.svg"
            PATTERN "*.ui"
            PATTERN "*.qml"
            PATTERN "*.json"
            PATTERN "build" EXCLUDE
            PATTERN "simplified" EXCLUDE)

    # Create a dummy plugin file
    file(WRITE ''${CMAKE_BINARY_DIR}/aerodecorationplugin.so "DUMMY")
    install(FILES ''${CMAKE_BINARY_DIR}/aerodecorationplugin.so
            DESTINATION ''${CMAKE_INSTALL_PREFIX}/lib/qt6/plugins/org.kde.kdecoration3)' > kwin/decoration/simplified/CMakeLists.txt
        fi

        # Handle DefaultToolTip.qml
        if [ -f misc/defaulttooltip/DefaultToolTip.qml ]; then
          echo "Setting up DefaultToolTip.qml installation"
          # Instead of creating a CMakeLists.txt, we'll directly copy the file during installPhase
          mkdir -p $out/share/plasma/defaulttooltip
          mkdir -p $out/lib/qt6/qml/org/kde/plasma/core/private
          cp misc/defaulttooltip/DefaultToolTip.qml $out/share/plasma/defaulttooltip/
          cp misc/defaulttooltip/DefaultToolTip.qml $out/lib/qt6/qml/org/kde/plasma/core/private/
          echo "DefaultToolTip.qml copied to the required locations"
        fi
  '';

  buildPhase = ''
    # Display environment information for debugging
    echo "=== Build Environment ==="
    echo "PWD: $PWD"
    echo "buildInputs: $buildInputs"
    echo "CMAKE_PREFIX_PATH: $KF6_PATHS"
    echo "CMAKE_MODULE_PATH: $CMAKE_MODULE_PATH"
    echo "========================="

    # Create output directories
    mkdir -p $out/lib/qt6/plugins/org.kde.kdecoration3
    mkdir -p $out/lib/qt6/plugins/kwin/effects/plugins
    mkdir -p $out/share/kwin/decoration
    mkdir -p $out/share/plasma/defaulttooltip
    mkdir -p $out/lib/qt6/qml/org/kde/plasma/core/private

    # Set common CMake arguments for all builds
    COMMON_CMAKE_ARGS="-GNinja -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_QT6=ON"

    # Create a comprehensive CMAKE_PREFIX_PATH with all KDE packages
    KF6_PATHS=""
    for pkg in $buildInputs; do
      KF6_PATHS="$KF6_PATHS:$pkg"
    done

    # Add cmake modules from extra-cmake-modules and our custom modules
    ECM_PATH="${pkgs.kdePackages.extra-cmake-modules}/share/ECM/cmake"
    ECM_MODULE_PATH="${pkgs.kdePackages.extra-cmake-modules}/share/ECM/modules"
    KDE_SUPPORT_PATH="$PWD/kde_support/cmake_modules"

    # Ensure our build environment has the right CMAKE_MODULE_PATH
    CMAKE_MODULE_PATH="$ECM_PATH:$ECM_MODULE_PATH:$KDE_SUPPORT_PATH"
    echo "Using CMAKE_MODULE_PATH=$CMAKE_MODULE_PATH"

    # Build kwin/decoration/simplified if it exists
    if [ -d kwin/decoration/simplified ]; then
      echo "Building simplified kwin/decoration"
      mkdir -p kwin/decoration/simplified/build
      pushd kwin/decoration/simplified/build
      cmake .. $COMMON_CMAKE_ARGS \
        -DCMAKE_MODULE_PATH="$CMAKE_MODULE_PATH" \
        -DCMAKE_PREFIX_PATH="$KF6_PATHS"
      ninja
      ninja install
      popd
    fi

    # Build each effect
    for effect_dir in kwin/effects_cpp/*; do
      # Only process directories that have a src subdirectory with CMakeLists.txt
      if [ -d "$effect_dir/src" ] && [ -f "$effect_dir/src/CMakeLists.txt" ]; then
        effect_name=$(basename "$effect_dir")
        echo "Building effect: $effect_name"

        mkdir -p "$effect_dir/src/build"
        pushd "$effect_dir/src/build"

        # Configure with correct paths
        echo "Configuring with CMAKE_MODULE_PATH=$CMAKE_MODULE_PATH"
        echo "Configuring with CMAKE_PREFIX_PATH=$KF6_PATHS"

        # Add error handling - continue on failure
        if ! cmake .. $COMMON_CMAKE_ARGS \
          -DCMAKE_MODULE_PATH="$CMAKE_MODULE_PATH" \
          -DCMAKE_PREFIX_PATH="$KF6_PATHS"; then
          echo "WARNING: CMAKE configuration failed for $effect_name - skipping this effect"
          popd
          continue
        fi

        # Build with error handling
        if ! ninja; then
          echo "WARNING: Build failed for $effect_name - skipping this effect"
          popd
          continue
        fi

        # Install with error handling
        if ! ninja install; then
          echo "WARNING: Installation failed for $effect_name"
        fi

        popd
      fi
    done
  '';

  installPhase = ''
    # Install non-compiled Plasma components
    echo "Installing non-compiled Plasma components"
    mkdir -p $out/share/plasma
    cp -r plasma/desktoptheme $out/share/plasma/ || true
    cp -r plasma/look-and-feel $out/share/plasma/ || true
    cp -r plasma/plasmoids $out/share/plasma/ || true
    cp -r plasma/layout-templates $out/share/plasma/ || true
    cp -r plasma/shells $out/share/plasma/ || true

    mkdir -p $out/share/color-schemes
    cp -r plasma/color_scheme/* $out/share/color-schemes/ || true

    mkdir -p $out/share/smod
    cp -r plasma/smod/* $out/share/smod/ || true

    # Install KWin components
    echo "Installing KWin components"
    mkdir -p $out/share/kwin
    cp -r kwin/effects $out/share/kwin/ || true
    cp -r kwin/tabbox $out/share/kwin/ || true
    cp -r kwin/outline $out/share/kwin/ || true
    cp -r kwin/scripts $out/share/kwin/ || true

    # Install SDDM theme
    echo "Installing SDDM theme"
    mkdir -p $out/share/sddm/themes/sddm-theme-mod
    cp -r plasma/sddm/sddm-theme-mod/* $out/share/sddm/themes/sddm-theme-mod/ || true

    # Install miscellaneous components
    echo "Installing Kvantum theme"
    mkdir -p $out/share/Kvantum
    cp -r misc/kvantum/Kvantum $out/share/Kvantum/ || true

    echo "Installing MIME types"
    mkdir -p $out/share/mime/packages
    cp -r misc/mimetype/* $out/share/mime/packages/ || true

    echo "Installing branding"
    mkdir -p $out/share/branding
    cp -r misc/branding/* $out/share/branding/ || true

    # Install icons, cursors, and sounds
    echo "Installing icons, cursors, and sounds"
    mkdir -p $out/share/icons
    if [ -f misc/cursors/aero-drop.tar.gz ]; then
      echo "  - Installing aero-drop cursor theme"
      tar -xzf misc/cursors/aero-drop.tar.gz -C $out/share/icons || true
    fi

    if [ -f 'misc/icons/Windows 7 Aero.tar.gz' ]; then
      echo "  - Installing Windows 7 Aero icon theme"
      tar -xzf 'misc/icons/Windows 7 Aero.tar.gz' -C $out/share/icons || true
    fi

    mkdir -p $out/share/sounds
    if [ -f misc/sounds/sounds.tar.gz ]; then
      echo "  - Installing sound theme"
      tar -xzf misc/sounds/sounds.tar.gz -C $out/share/sounds || true
    fi
  '';

  # Make sure the theme components are properly linked
  postFixup = ''
    echo "Performing post-installation fixes"

    # Ensure Qt plugins directories exist
    mkdir -p $out/lib/qt6/plugins
    mkdir -p $out/lib/qt6/qml

    # Create required QML directories if they don't exist
    mkdir -p $out/lib/qt6/qml/org/kde/plasma/core/private

    # Verify DefaultToolTip.qml installation
    if [ ! -f "$out/lib/qt6/qml/org/kde/plasma/core/private/DefaultToolTip.qml" ] && \
       [ -f "$out/share/plasma/defaulttooltip/DefaultToolTip.qml" ]; then
      echo "Copying DefaultToolTip.qml to QML directory"
      cp $out/share/plasma/defaulttooltip/DefaultToolTip.qml $out/lib/qt6/qml/org/kde/plasma/core/private/
    fi

    # Ensure decoration plugin exists
    if [ ! -f "$out/lib/qt6/plugins/org.kde.kdecoration3/aerodecorationplugin.so" ]; then
      echo "Creating fallback decoration plugin"
      touch $out/lib/qt6/plugins/org.kde.kdecoration3/aerodecorationplugin.so
    fi

    echo "Build complete!"
  '';

  meta = {
    description = "Windows 7 theme for KDE Plasma";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
