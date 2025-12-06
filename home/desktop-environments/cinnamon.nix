{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.cinnamon.enable = lib.mkEnableOption "Cinnamon home tweaks";

  config = lib.mkIf config.home.cinnamon.enable {
    dconf.settings = {
      # Core Cinnamon settings
      "org/cinnamon" = {
        enabled-applets = [
          "menu@cinnamon.org"
          "show-desktop@cinnamon.org"
          "window-list@cinnamon.org"
          "sound@cinnamon.org"
          "keyboard@cinnamon.org"
        ];
      };
      # Theme and appearance (essential tweaks)
      "org/cinnamon/desktop/theme" = {
        name = "Yaru-dark";
      };
      "org/cinnamon/desktop/interface" = {
        icon-theme = "Yaru-dark";
        font-name = "Sans 11";
      };
      "org/cinnamon/desktop/wm/preferences" = {
        theme = "Yaru-dark";
      };
      # Nemo file manager tweaks (essential for usability)
      "org/nemo/preferences" = {
        show-image-thumbnails = true;
        show-directory-item-counts = true;
        always-use-location-entry = true;
      };
    };
    # User packages for Cinnamon enhancements
    home.packages = with pkgs; [
      dconf # For manual tweaks if needed
      # gnome-tweaks partially works, but Cinnamon has its own control center
    ];
  };
}
