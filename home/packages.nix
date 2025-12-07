{pkgs, ...}: {
  # Packages https://search.nixos.org/packages
  home.packages = with pkgs; [
    # User applications
    brave
    discord
    # code-cursor
    zed-editor
    firefox
    mailspring
    # zoom-us
    gimp
    vlc
    onedrivegui
    signal-desktop-bin
    libreoffice
    qbittorrent
    # xivlauncher
    # trezor-suite
    # minder
    # teams-for-linux
    element-desktop
    anki-bin
    # teamspeak6-client
    # youtube-music
    # pdfsam-basic
    bitwarden-desktop
    # VM management GUI tools (user-level)
    # virt-manager
    # virt-viewer
    # looking-glass-client
  ];
  services.flatpak = {
    enable = true; # Enables user-level Flatpak
    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      # {
      #   appId = "dev.zed.Zed";
      #   origin = "flathub";
      # }
      # {
      #   appId = "com.getmailspring.Mailspring";
      #   origin = "flathub";
      # }
    ];
    # Optional: overrides, update policy, etc.
  };
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
}
