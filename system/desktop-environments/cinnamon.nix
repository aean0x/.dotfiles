{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.cinnamon.enable = lib.mkEnableOption "Cinnamon desktop environment";

  config = lib.mkIf config.services.cinnamon.enable {
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.cinnamon.enable = true;
    };

    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    environment.systemPackages = with pkgs; [
      nemo-with-extensions
      file-roller
    ];
  };
}
