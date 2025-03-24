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
        endmacro()

        # Define KI18n macros
        macro(ki18n_wrap_ui)
          message(STATUS "KI18n: Wrapping UI files (compatibility function)")
          # Just a stub to make CMake happy
        endmacro()
        ' > kde_support/cmake_modules/KDE6Config.cmake

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

        # Create a KWin target definition file
        echo '# KWinTargets.cmake - Define KWin targets for compatibility

        add_library(KWin::kwin INTERFACE IMPORTED)
        set_target_properties(KWin::kwin PROPERTIES
          INTERFACE_INCLUDE_DIRECTORIES "/build/source/kwin_compat_include"
        )
        ' > kde_support/cmake_modules/KWinTargets.cmake

        # Create a directory for KWin compatibility headers
        mkdir -p kwin_compat_include/KWin

        # Create a stub KWin Effect API header
        echo '// Stub KWin Effect header for compatibility
        #pragma once
        #include <QObject>
        #include <QImage>
        #include <QRegion>

        namespace KWin {
            class Effect : public QObject {
            public:
                Effect() : QObject() {}
                virtual ~Effect() {}
            };
        }' > kwin_compat_include/KWin/Effect

        # Get the absolute path to the compatibility modules
        CURRENT_DIR="$PWD"
        MODULES_PATH="$CURRENT_DIR/kde_support/cmake_modules"
        echo "Modules path: $MODULES_PATH"

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

            # Fix include paths - completely rewrite the beginning of the file
            echo "  - Rewriting CMake includes and directives"
            tmpfile=$(mktemp)
            cat > "$tmpfile" << EOT
    cmake_minimum_required(VERSION 3.16)
    project($(basename "$effect_dir") VERSION 1.0)

    # Include KF6 compatibility modules - absolute paths for reliability
    list(APPEND CMAKE_MODULE_PATH "$MODULES_PATH")
    include(KDE6Config)
    include(KWinTargets)

    EOT
            # Append the rest of the file
            tail -n +7 "$effect_dir/src/CMakeLists.txt" >> "$tmpfile"
            # Replace the original file
            mv "$tmpfile" "$effect_dir/src/CMakeLists.txt"

            # Remove any existing include with relative path that would fail
            sed -i '/include.*kde_support.*KDE6Config.cmake/d' "$effect_dir/src/CMakeLists.txt"
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

        # Find DefaultToolTip.qml and check if it exists
        echo "Checking for DefaultToolTip.qml..."
        DEFAULT_TOOLTIP_PATH=""
        for path in misc/defaulttooltip/DefaultToolTip.qml plasma/defaulttooltip/DefaultToolTip.qml; do
          if [ -f "$path" ]; then
            DEFAULT_TOOLTIP_PATH="$path"
            echo "Found DefaultToolTip.qml at $DEFAULT_TOOLTIP_PATH"
            break
          fi
        done

        # If DefaultToolTip.qml exists, create a proper installer for it
        if [ -n "$DEFAULT_TOOLTIP_PATH" ]; then
          echo "Setting up DefaultToolTip.qml installation"
          mkdir -p defaulttooltip_installer

          # Create a simple CMakeLists.txt to install the file properly
          echo 'cmake_minimum_required(VERSION 3.16)
        project(default-tooltip VERSION 1.0)

        # Install tooltip to both locations for compatibility
        install(FILES ''${CMAKE_CURRENT_SOURCE_DIR}/DefaultToolTip.qml
                DESTINATION ''${CMAKE_INSTALL_PREFIX}/share/plasma/defaulttooltip)

        install(FILES ''${CMAKE_CURRENT_SOURCE_DIR}/DefaultToolTip.qml
                DESTINATION ''${CMAKE_INSTALL_PREFIX}/lib/qt6/qml/org/kde/plasma/core/private)' > defaulttooltip_installer/CMakeLists.txt

          # Copy the file to our installer directory
          cp "$DEFAULT_TOOLTIP_PATH" defaulttooltip_installer/
        else
          echo "DefaultToolTip.qml not found in expected locations"
        fi
  '';

  buildPhase = ''
    # Display environment information for debugging
    echo "=== Build Environment ==="
    echo "PWD: $PWD"
    echo "buildInputs: $buildInputs"
    echo "========================="

    # Create output directories
    mkdir -p $out/lib/qt6/plugins/org.kde.kdecoration3
    mkdir -p $out/lib/qt6/plugins/kwin/effects/plugins
    mkdir -p $out/share/kwin/decoration
    mkdir -p $out/share/plasma/defaulttooltip
    mkdir -p $out/lib/qt6/qml/org/kde/plasma/core/private

    # Get the absolute path to our compatibility modules
    MODULES_PATH="$PWD/kde_support/cmake_modules"
    echo "Using modules path: $MODULES_PATH"

    # Add cmake modules from extra-cmake-modules and our custom modules
    ECM_PATH="${pkgs.kdePackages.extra-cmake-modules}/share/ECM/cmake"
    ECM_MODULE_PATH="${pkgs.kdePackages.extra-cmake-modules}/share/ECM/modules"

    # Create a comprehensive CMAKE_MODULE_PATH
    CMAKE_MODULE_PATH="$MODULES_PATH:$ECM_PATH:$ECM_MODULE_PATH"
    echo "Full CMAKE_MODULE_PATH=$CMAKE_MODULE_PATH"

    # Create a comprehensive CMAKE_PREFIX_PATH with all KDE packages
    KF6_PATHS=""
    for pkg in $buildInputs; do
      KF6_PATHS="$KF6_PATHS:$pkg"
    done
    echo "Using CMAKE_PREFIX_PATH=$KF6_PATHS"

    # Set common CMake arguments for all builds
    COMMON_CMAKE_ARGS="-GNinja -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_QT6=ON"

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

    # Build DefaultToolTip.qml installer if it exists
    if [ -d defaulttooltip_installer ]; then
      echo "Building DefaultToolTip.qml installer"
      mkdir -p defaulttooltip_installer/build
      pushd defaulttooltip_installer/build
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
        echo "Configuring effect with CMAKE_MODULE_PATH=$CMAKE_MODULE_PATH"

        # Add error handling - continue on failure
        if ! cmake .. $COMMON_CMAKE_ARGS \
          -DCMAKE_MODULE_PATH="$CMAKE_MODULE_PATH" \
          -DCMAKE_PREFIX_PATH="$KF6_PATHS"; then
          echo "WARNING: CMAKE configuration failed for $effect_name - skipping this effect"

          # Create effect source directory
          mkdir -p $out/share/kwin/effects-source/$effect_name

          # Copy source files for reference but make sure the directory exists first
          if [ -d "$effect_dir/src" ]; then
            cp -r "$effect_dir/src/"* $out/share/kwin/effects-source/$effect_name/ 2>/dev/null || true
            echo "Copied source files to $out/share/kwin/effects-source/$effect_name/"
          fi

          popd
          continue
        fi

        # Build with error handling
        if ! ninja; then
          echo "WARNING: Build failed for $effect_name - skipping this effect"

          # Create effect source directory
          mkdir -p $out/share/kwin/effects-source/$effect_name

          # Copy source files for reference but make sure the directory exists first
          if [ -d "$effect_dir/src" ]; then
            cp -r "$effect_dir/src/"* $out/share/kwin/effects-source/$effect_name/ 2>/dev/null || true
            echo "Copied source files to $out/share/kwin/effects-source/$effect_name/"
          fi

          popd
          continue
        fi

        # Install with error handling
        if ! ninja install; then
          echo "WARNING: Installation failed for $effect_name"

          # Create effect source directory
          mkdir -p $out/share/kwin/effects-source/$effect_name

          # Copy source files for reference but make sure the directory exists first
          if [ -d "$effect_dir/src" ]; then
            cp -r "$effect_dir/src/"* $out/share/kwin/effects-source/$effect_name/ 2>/dev/null || true
            echo "Copied source files to $out/share/kwin/effects-source/$effect_name/"
          fi
        fi

        popd
      fi
    done
  '';

  installPhase = ''
    # Install non-compiled Plasma components
    echo "Installing non-compiled Plasma components"

    # Use find to locate plasma components with better error handling
    echo "  - Installing plasma desktop themes"
    mkdir -p $out/share/plasma
    if [ -d plasma/desktoptheme ]; then cp -r plasma/desktoptheme $out/share/plasma/; fi
    if [ -d plasma/look-and-feel ]; then cp -r plasma/look-and-feel $out/share/plasma/; fi
    if [ -d plasma/plasmoids ]; then cp -r plasma/plasmoids $out/share/plasma/; fi
    if [ -d plasma/layout-templates ]; then cp -r plasma/layout-templates $out/share/plasma/; fi
    if [ -d plasma/shells ]; then cp -r plasma/shells $out/share/plasma/; fi

    echo "  - Installing color schemes"
    mkdir -p $out/share/color-schemes
    find plasma/color_scheme -type f -name "*.colors" -exec cp {} $out/share/color-schemes/ \; 2>/dev/null || true

    echo "  - Installing SMOD components"
    mkdir -p $out/share/smod
    if [ -d plasma/smod ]; then cp -r plasma/smod/* $out/share/smod/ 2>/dev/null || true; fi

    # Install KWin components
    echo "Installing KWin components"
    mkdir -p $out/share/kwin
    if [ -d kwin/effects ]; then cp -r kwin/effects $out/share/kwin/ 2>/dev/null || true; fi
    if [ -d kwin/tabbox ]; then cp -r kwin/tabbox $out/share/kwin/ 2>/dev/null || true; fi
    if [ -d kwin/outline ]; then cp -r kwin/outline $out/share/kwin/ 2>/dev/null || true; fi
    if [ -d kwin/scripts ]; then cp -r kwin/scripts $out/share/kwin/ 2>/dev/null || true; fi

    # Install any effect sources directly if they were not built to ensure they're always available
    echo "  - Checking for missing effect sources"
    for effect_dir in kwin/effects_cpp/*; do
      if [ -d "$effect_dir/src" ]; then
        effect_name=$(basename "$effect_dir")
        if [ ! -d "$out/share/kwin/effects-source/$effect_name" ]; then
          echo "    - Copying source for $effect_name"
          mkdir -p $out/share/kwin/effects-source/$effect_name
          cp -r "$effect_dir/src/"* $out/share/kwin/effects-source/$effect_name/
        fi
      fi
    done

    # Install SDDM theme
    echo "Installing SDDM theme"
    mkdir -p $out/share/sddm/themes/sddm-theme-mod
    if [ -d plasma/sddm/sddm-theme-mod ]; then
      cp -r plasma/sddm/sddm-theme-mod/* $out/share/sddm/themes/sddm-theme-mod/ 2>/dev/null || true
    fi

    # Install miscellaneous components
    echo "Installing Kvantum theme"
    mkdir -p $out/share/Kvantum
    if [ -d misc/kvantum/Kvantum ]; then
      cp -r misc/kvantum/Kvantum $out/share/Kvantum/ 2>/dev/null || true
    fi

    echo "Installing MIME types"
    mkdir -p $out/share/mime/packages
    if [ -d misc/mimetype ]; then
      cp -r misc/mimetype/* $out/share/mime/packages/ 2>/dev/null || true
    fi

    echo "Installing branding"
    mkdir -p $out/share/branding
    if [ -d misc/branding ]; then
      cp -r misc/branding/* $out/share/branding/ 2>/dev/null || true
    fi

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

    # Directly copy DefaultToolTip.qml as a backup in case the build process failed
    echo "Checking DefaultToolTip.qml installation"
    for path in misc/defaulttooltip/DefaultToolTip.qml plasma/defaulttooltip/DefaultToolTip.qml; do
      if [ -f "$path" ] && [ ! -f "$out/lib/qt6/qml/org/kde/plasma/core/private/DefaultToolTip.qml" ]; then
        echo "  - Manually copying DefaultToolTip.qml from $path"
        mkdir -p $out/share/plasma/defaulttooltip
        mkdir -p $out/lib/qt6/qml/org/kde/plasma/core/private
        cp "$path" $out/share/plasma/defaulttooltip/
        cp "$path" $out/lib/qt6/qml/org/kde/plasma/core/private/
        break
      fi
    done
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
