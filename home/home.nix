{
  config,
  pkgs,
  lib,
  username,
  inputs,
  ...
}: let
  secrets = import ./secrets.nix;
in {
  # Programs with options https://home-manager-options.extranix.com/
  programs = {
    fzf.enable = true;
    home-manager.enable = true;
    bash = {
      enable = true;
      initExtra = ''
        export PATH=$PATH:$HOME/.local/bin
      '';
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  # Packages https://search.nixos.org/packages
  home.packages = with pkgs; [
    # User applications
    brave
    firefox
    discord
    code-cursor
    zoom-us
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
    trezor-suite
    minder
    masterpdfeditor
    teams-for-linux
    element-desktop
    anki-bin
    teamspeak6-client
    youtube-music
    pdfsam-basic
    mailspring

    # VM management GUI tools (user-level)
    virt-manager
    virt-viewer
    stable.looking-glass-client
  ];

  # # Flatpak packages
  # services.flatpak.packages = [
  #   # { appId = "com.brave.Browser"; origin = "flathub";  }
  #   "com.getmailspring.Mailspring"
  # ];

  # # # Flatpak settings
  # services.flatpak = {
  #   enable = true;
  #   update.auto.enable = true;
  #   uninstallUnmanaged = true;
  #   remotes = lib.mkOptionDefault [
  #     {
  #       name = "flathub-beta";
  #       location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
  #     }
  #   ];
  # };

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
    stateVersion = "24.05";
  };
  systemd.user.startServices = "sd-switch";
}
