# AeroThemePlasma Compiled Components

This document lists all the components that are compiled during the Docker build process and identifies where they should be installed in the system.

## Build Process Overview

The AeroThemePlasma compilation process involves several key components:

1. **DefaultToolTip** - Custom tooltip component for Plasma
2. **KWin Decoration** - Window decoration theme for KWin
3. **KWin Effects** - Various visual effects for the KWin window manager

Each of these is built using CMake and Ninja, with files installed to standard system directories which we then copy to our output directories.

## Component Installation Paths

### 1. DefaultToolTip Component

**Source Location**: `aerothemeplasma/misc/defaulttooltip`

**Build Output**:
- `/usr/lib/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so` (system path)
- `/usr/lib/qt6/qml/org/kde/plasma/core/DefaultToolTip.qml` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so`
- `$out/lib/qt6/qml/org/kde/plasma/core/DefaultToolTip.qml`

**User Installation Path**:
- `$HOME/.local/lib/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so`
- `$HOME/.local/lib/qt6/qml/org/kde/plasma/core/DefaultToolTip.qml`

### 2. KWin Decoration

**Source Location**: `aerothemeplasma/kwin/decoration`

**Build Output**:
- `/usr/lib/qt6/plugins/org.kde.kdecoration3/aerothemeplasma.so` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/plugins/org.kde.kdecoration3/aerothemeplasma.so`

**User Installation Path**:
- `$HOME/.local/lib/qt6/plugins/org.kde.kdecoration3/aerothemeplasma.so`

### 3. KWin Effects

#### 3.1. Aero Glass Blur

**Source Location**: `aerothemeplasma/kwin/effects_cpp/kde-effects-aeroglassblur`

**Build Output**:
- `/usr/lib/qt6/plugins/kwin/effects/plugins/aeroglassblur.so` (system path)
- `/usr/lib/qt6/plugins/kwin/effects/configs/kwin_aeroglassblur_config.so` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/plugins/kwin/effects/plugins/aeroglassblur.so`
- `$out/lib/qt6/plugins/kwin/effects/configs/kwin_aeroglassblur_config.so`

**User Installation Path**:
- `$HOME/.local/lib/qt6/plugins/kwin/effects/plugins/aeroglassblur.so`
- `$HOME/.local/lib/qt6/plugins/kwin/effects/configs/kwin_aeroglassblur_config.so`

#### 3.2. Aero Glide

**Source Location**: `aerothemeplasma/kwin/effects_cpp/aeroglide`

**Build Output**:
- `/usr/lib/qt6/plugins/kwin/effects/plugins/aeroglide.so` (system path)
- `/usr/lib/qt6/plugins/kwin/effects/configs/kwin_aeroglide_config.so` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/plugins/kwin/effects/plugins/aeroglide.so`
- `$out/lib/qt6/plugins/kwin/effects/configs/kwin_aeroglide_config.so`

**User Installation Path**:
- `$HOME/.local/lib/qt6/plugins/kwin/effects/plugins/aeroglide.so`
- `$HOME/.local/lib/qt6/plugins/kwin/effects/configs/kwin_aeroglide_config.so`

#### 3.3. SMOD Glow

**Source Location**: `aerothemeplasma/kwin/effects_cpp/smodglow`

**Build Output**:
- `/usr/lib/qt6/plugins/kwin/effects/plugins/smodglow.so` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/plugins/kwin/effects/plugins/smodglow.so`

**User Installation Path**:
- `$HOME/.local/lib/qt6/plugins/kwin/effects/plugins/smodglow.so`

#### 3.4. SMOD Snap

**Source Location**: `aerothemeplasma/kwin/effects_cpp/kwin-effect-smodsnap-v2`

**Build Output**:
- `/usr/lib/qt6/plugins/kwin/effects/plugins/smodsnap.so` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/plugins/kwin/effects/plugins/smodsnap.so`

**User Installation Path**:
- `$HOME/.local/lib/qt6/plugins/kwin/effects/plugins/smodsnap.so`

#### 3.5. Startup Feedback

**Source Location**: `aerothemeplasma/kwin/effects_cpp/startupfeedback`

**Build Output**:
- `/usr/lib/qt6/plugins/kwin/effects/plugins/startupfeedback.so` (system path)

**Nix Distribution Path**:
- `$out/lib/qt6/plugins/kwin/effects/plugins/startupfeedback.so`

**User Installation Path**:
- `$HOME/.local/lib/qt6/plugins/kwin/effects/plugins/startupfeedback.so`

## Summary of Required System Files

Here's a consolidated list of all system files that should be included in the Nix derivation:

```
lib/qt6/qml/org/kde/plasma/core/libcorebindingsplugin.so
lib/qt6/qml/org/kde/plasma/core/DefaultToolTip.qml
lib/qt6/plugins/org.kde.kdecoration3/aerothemeplasma.so
lib/qt6/plugins/kwin/effects/plugins/aeroglassblur.so
lib/qt6/plugins/kwin/effects/configs/kwin_aeroglassblur_config.so
lib/qt6/plugins/kwin/effects/plugins/aeroglide.so
lib/qt6/plugins/kwin/effects/configs/kwin_aeroglide_config.so
lib/qt6/plugins/kwin/effects/plugins/smodglow.so
lib/qt6/plugins/kwin/effects/plugins/smodsnap.so
lib/qt6/plugins/kwin/effects/plugins/startupfeedback.so
```

## Verification Checks

To verify that these components have been properly built and installed, you can:

1. Check if the compiled binaries exist in the Docker build output at `$HOME/.cache/aerothemeplasma-build/output/lib/qt6/`
2. Check if they've been copied to the user location at `$HOME/.local/lib/qt6/`
3. Test functionality by enabling the corresponding KWin effects and checking if they work

Use the `verify-aerotheme.sh` script to automate these verification checks. 