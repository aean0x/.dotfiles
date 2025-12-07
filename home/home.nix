{
  lib,
  stateVersion,
  ...
}: let
  secrets = import ./secrets.nix;
in {
  imports = [
    ./packages.nix
    ./desktop-environments/cinnamon.nix
  ];

  # User-specific DM settings toggle
  home.cinnamon.enable = true;

  # Dotfiles tracking: Add files to be symlinked to the home directory on nixos-rebuild
  home.file =
    lib.foldl'
    (
      acc: file:
        acc
        // {
          "${file.target}" = {
            source = file.source;
            executable = file.executable;
          };
        }
    )
    {}
    [
      {
        source = ./bin/rebuild;
        target = ".local/bin/rebuild";
        executable = true;
      }
      {
        source = ./bin/cleanup;
        target = ".local/bin/cleanup";
        executable = true;
      }
    ];
  dconf.settings = {
    "org/virt-manager/virt-manager" = {
      system-tray = true;
      xmleditor-enabled = true;
    };
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
  # Home-Manager settings
  home = {
    username = secrets.username;
    homeDirectory = lib.mkForce "/home/${secrets.username}";
    stateVersion = stateVersion;
  };
  systemd.user.startServices = "sd-switch";
}
