{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  secrets = import ./secrets.nix;
in {
  # Programs with options https://home-manager-options.extranix.com/
  programs = {
    vscode.enable = true;
    fzf.enable = true;
    home-manager.enable = true;
    bash = {
      enable = true;
      initExtra = ''
        export PATH=$PATH:$HOME/.local/bin
      '';
    };
  };

  # Packages https://search.nixos.org/packages
  home.packages = with pkgs; [
    brave
    discord
    gimp
    inkscape
    vlc
    turbovnc
    thunderbird
    pantheon.elementary-mail
    onedrivegui
    signal-desktop
    libreoffice
    qbittorrent
    xivlauncher
    openshot-qt
  ];

  # Flatpak packages
  services.flatpak.packages = [
    # { appId = "com.brave.Browser"; origin = "flathub";  }
    "im.riot.Riot"
    "com.github.IsmaelMartinez.teams_for_linux"
    "com.usebottles.bottles"
  ];

  # Flatpak settings
  services.flatpak = {
    enable = true;
    update.auto.enable = true;
    uninstallUnmanaged = true;
    remotes = lib.mkOptionDefault [
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
    ];
  };

  # Dotfiles tracking: Add files to be symlinked to the home directory on nixos-rebuild
  home.file =
    lib.foldl' (
      acc: file:
        acc
        // {
          "${file.target}" = {
            source = file.source;
            executable = file.executable;
          };
        }
    ) {} [
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
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Home-Manager settings
  home = {
    username = secrets.username;
    homeDirectory = lib.mkForce "/home/${secrets.username}";
    stateVersion = "24.05";
  };
  nixpkgs.config.allowUnfree = true;
  systemd.user.startServices = "sd-switch";
}
