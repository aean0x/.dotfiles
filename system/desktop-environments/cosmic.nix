{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.cosmic.enable = lib.mkEnableOption "COSMIC desktop environment";

  config = lib.mkIf config.services.cosmic.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.cosmic-greeter.enableGnomeKeyring = true;
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-cosmic pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal];

    nix.settings = {
      substituters = ["https://cosmic.cachix.org/"];
      trusted-public-keys = ["cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="];
    };
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    environment.systemPackages = with pkgs; [
      cosmic-store
      cosmic-reader
      cosmic-wallpapers
      libsecret
      seahorse
    ];
  };
}
