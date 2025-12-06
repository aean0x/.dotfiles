{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.cinnamon.enable = lib.mkEnableOption "Cinnamon desktop environment";

  config = lib.mkIf config.services.cinnamon.enable {
    services.xserver.enable = true;
    #exportConfiguration = false;
    services.xserver.displayManager.lightdm.enable = true;
    services.xserver.desktopManager.cinnamon.enable = true;
    #services.displayManager.defaultSession = "cinnamon";
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    environment.systemPackages = with pkgs; [
      nemo-with-extensions
      file-roller
    ];
  };
}
