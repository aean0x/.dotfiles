{
  inputs,
  lib,
  ...
}: {
  # None of these actually work. I found another easier way to do this.
  # I'll get back to this later when I have an actual reason to use overlays.
  # I have a feeling syntax is right but I'm missing some key concept behind how overlays are done. idk.
  # Leaving this here for now.

  # https://nixos.wiki/wiki/Overlays
  # plasma-workspace-custom = final: prev: {
  #   plasma-workspace = prev.plasma-workspace.overrideAttrs (oldAttrs: {
  #     postInstall =
  #       oldAttrs.postInstall
  #       + ''
  #         substituteInPlace $out/share/sddm/themes/breeze/theme.conf \
  #           --replace "[General]" "[General]\nbackground=/run/current-system/sw/share/wallpapers/Elarun/contents/images/2560x1600.png\nGreeterEnvironment=\"QT_SCREEN_SCALE_FACTORS=0.75\""
  #       '';
  #   });
  # };

  # kdePackages = prev: final: {
  #   plasma-workspace = final.kdePackages.plasma-workspace.overrideAttrs (oldAttrs: {
  #     postInstall =
  #       oldAttrs.postInstall
  #       + ''
  #         sed -i 's|^background=.*|background=${lib.getBin breeze}/share/wallpapers/Elarun/contents/images/2560x1600.png\nGreeterEnvironment=\"QT_SCREEN_SCALE_FACTORS=0.75\"|' $out/share/sddm/themes/breeze/theme.conf
  #         touch $out/share/sddm/themes/breeze/theme1.conf
  #       '';
  #   });
  # };

  #   plasma-workspace-custom = final: prev: {
  #     plasma-workspace = prev.plasma-workspace.overrideAttrs (oldAttrs: {
  #       postInstall =
  #         oldAttrs.postInstall
  #         + ''
  #           echo "[General]
  #           background=/run/current-system/sw/share/wallpapers/Elarun/contents/images/2560x1600.png
  #           GreeterEnvironment=\"QT_SCREEN_SCALE_FACTORS=0.75\"" > $out/share/sddm/themes/breeze/theme.conf
  #         '';
  #     });
  #   };

  #   plasma-workspace-custom = final: prev: {
  #     plasma-workspace = prev.plasma-workspace.overrideAttrs (oldAttrs: {
  #       postInstall =
  #         oldAttrs.postInstall
  #         + ''
  #           mv $out/share/sddm/themes/breeze/theme.conf $out/share/sddm/themes/breeze/theme.conf.bak
  #           install -Dm644 /path/to/your/theme.conf $out/share/sddm/themes/breeze/theme.conf
  #         '';
  #     });
  #   };

  # unstable-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
}
