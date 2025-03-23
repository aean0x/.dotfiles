{
  stdenv,
  lib,
  bash,
  coreutils,
  git,
  docker,
  gnused,
  gnutar,
  gzip,
  fetchzip,
  writeScriptBin,
}: let
  # Fetch the repository using fetchzip into the Nix store
  themeRepo = fetchzip {
    url = "https://gitgud.io/wackyideas/aerothemeplasma/-/archive/master/aerothemeplasma-master.zip";
    sha256 = "sha256-vnYi1uV3HUAAyZhPMPazI/1V6x88QoknKNBiMiVBGYA=";
  };

  # Build script
  buildScript = writeScriptBin "build-aerotheme" ''
      #!/bin/bash
      set -e
      REPO_DIR="${themeRepo}"
      OUTPUT_DIR="$HOME/.cache/aerothemeplasma-build/output"
      log() { echo "$@" >&2; }
      log "=== Building AeroThemePlasma ==="
      safe_clean_dir() {
        local dir="$1"
        if [ -d "$dir" ]; then
          log "Cleaning directory: $dir"
          rm -rf "$dir" || { log "Failed to clean $dir, proceeding anyway."; }
        fi
        mkdir -p "$dir"
        chmod -R u+rwX "$dir" || true
      }
      safe_clean_dir "$OUTPUT_DIR"
      mkdir -p "$OUTPUT_DIR/lib/qt6/qml/org/kde/plasma/core" \
               "$OUTPUT_DIR/lib/qt6/plugins/org.kde.kdecoration3" \
               "$OUTPUT_DIR/lib/qt6/plugins/kwin/effects/plugins" \
               "$OUTPUT_DIR/lib/qt6/plug
    ins/kwin/effects/configs"
      cp -r "$REPO_DIR"/* "$OUTPUT_DIR/"
      chmod -R u+w "$OUTPUT_DIR"  # Added to fix permission issues
      if command -v docker >/dev/null; then
        log "Building with Docker..."
        USER_ID=$(id -u)
        GROUP_ID=$(id -g)
        USER_NAME=$(whoami)
        DOCKER_SCRIPT=$(mktemp)
        chmod +x "$DOCKER_SCRIPT"
        cat > "$DOCKER_SCRIPT" << EOF
    #!/bin/bash
    set -e
    pacman -Syu --noconfirm
    pacman -S --noconfirm cmake extra-cmake-modules ninja qt6-virtualkeyboard qt6-multimedia qt6-5compat plasma-wayland-protocols plasma5support kvantum base-devel plasma-workspace
    groupadd -g $GROUP_ID $USER_NAME || true
    useradd -u $USER_ID -g $GROUP_ID -m $USER_NAME || true
    echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER_NAME
    chown -R $USER_ID:$GROUP_ID /workspace
    sudo -u $USER_NAME bash -c '
      cd /workspace/misc/defaulttooltip && bash install_ninja.sh || echo "DefaultToolTip failed, continuing..."
      cd /workspace/kwin/decoration && bash install_ninja.sh || echo "Decoration failed, continuing..."
      for effect in /workspace/kwin/effects_cpp/*; do
        if [ -d "\$effect" ]; then
          cd "\$effect" && bash install_ninja.sh || echo "\$(basename \$effect) failed, continuing..."
        fi
      done
    '
    cp -r /usr/lib/qt6/qml/org/kde/plasma/core/* /workspace/lib/qt6/qml/org/kde/plasma/core/ 2>/dev/null || true
    cp -r /usr/lib/qt6/plugins/org.kde.kdecoration3/* /workspace/lib/qt6/plugins/org.kde.kdecoration3/ 2>/dev/null || true
    cp -r /usr/lib/qt6/plugins/kwin/effects/plugins/* /workspace/lib/qt6/plugins/kwin/effects/plugins/ 2>/dev/null || true
    cp -r /usr/lib/qt6/plugins/kwin/effects/configs/* /workspace/lib/qt6/plugins/kwin/effects/configs/ 2>/dev/null || true
    for build_file in \$(find /workspace/kwin/decoration/build-kf6 -name "*.so" 2>/dev/null); do
      cp -f "\$build_file" /workspace/lib/qt6/plugins/org.kde.kdecoration3/
    done
    for effect_dir in /workspace/kwin/effects_cpp/*; do
      if [ -d "\$effect_dir/build-kf6" ]; then
        for effect_file in \$(find "\$effect_dir/build-kf6" -name "*.so" 2>/dev/null); do
          cp -f "\$effect_file" /workspace/lib/qt6/plugins/kwin/effects/plugins/
        done
      fi
    done
    chown -R $USER_ID:$GROUP_ID /workspace
    EOF
        docker run --rm -v "$OUTPUT_DIR:/workspace:rw" -v "$DOCKER_SCRIPT:/script.sh:ro" archlinux:latest /script.sh || log "Docker build failed, using source files only."
        rm -f "$DOCKER_SCRIPT"
      else
        log "Docker not found, using source files only."
      fi
      chmod -R u+rwX "$OUTPUT_DIR" || true
      log "Build complete at: $OUTPUT_DIR"
  '';
in
  stdenv.mkDerivation {
    name = "aerothemeplasma";
    src = themeRepo;

    nativeBuildInputs = [bash coreutils git docker gnused gnutar gzip];

    # No unpackPhase; extraction happens in installPhase
    buildPhase = "true"; # No build steps required

    installPhase = ''
      mkdir -p $out/bin $out/share/aerothemeplasma/source $out/share/aerothemeplasma/icons $out/share/aerothemeplasma/sounds

      # Copy the main repository files
      cp -r $src/* $out/share/aerothemeplasma/source/

      # Extract aero-drop icons to $out/share/aerothemeplasma/icons
      tar -xzf "$src/misc/icons/Windows 7 Aero.tar.gz" -C $out/share/aerothemeplasma/icons

      # Extract sounds to $out/share/aerothemeplasma/sounds
      tar -xzf $src/misc/sounds/sounds.tar.gz -C $out/share/aerothemeplasma/sounds

      # Copy the build script
      cp ${buildScript}/bin/build-aerotheme $out/bin/
    '';

    meta = {
      description = "Windows 7 theme for KDE Plasma";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.linux;
    };
  }
