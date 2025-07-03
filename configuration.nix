{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  secrets = import ./home/secrets.nix;
in {
  # Programs with options https://search.nixos.org/options
  programs = {
    git.enable = true;
    dconf.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
    };
    virt-manager.enable = true;
  };

  # Packages https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    # Tools
    curl
    wget
    usbutils
    alejandra
    ltunify
    ffmpeg
    kubectl
    mono
    p7zip
    unrar
    unzip
    exfatprogs
    hashcat
    hpl
    gptfdisk
    cdrkit
    gnome-disk-utility
    cloudflared
    bottles
    picocom
    neofetch
    openvpn3
    sops
    tree

    # Flatpak management
    gnome-software

    # Build tools
    cmake
    dlib
    bison
    flex
    fontforge
    makeWrapper
    pkg-config
    gnumake
    libiconv
    autoconf
    automake
    libtool
    ninja
    libgcc
    gcc
    libGL
    mesa
    libglvnd

    # VM/KVM tools
    docker-compose
    qemu
    OVMF
    spice
    spice-gtk
    spice-protocol
    virt-viewer
    libguestfs
    bridge-utils
    seabios
    dmg2img
    tesseract
    screen

    # oops all global packages
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    python312
    python312Packages.torch-bin
    python312Packages.pybind11
    python312Packages.pip
    python312Packages.dlib
    python312Packages.tensorflow-bin

    # Wine
    wineWow64Packages.fonts
    wineWow64Packages.waylandFull
    winetricks

    # Hardware
    vulkan-tools
    vulkan-headers
    dxvk
    pciutils
    glxinfo
    lshw

    # User-chosen applications (not theme dependencies)
    kdePackages.yakuake
    kdePackages.skanlite
    kdePackages.kdenlive
    kdePackages.okular
    kdePackages.elisa
    kdePackages.kcalc
    kdePackages.ksystemlog
    kdePackages.kolourpaint
    kdePackages.isoimagewriter
    kdePackages.filelight

    # Package derivation template
    # (writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
    #   [General]
    #   background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Mountain/contents/images_dark/5120x2880.png
    # '')
  ];

  # Services settings
  services = {
    flatpak.enable = true;
    printing = {
      enable = true;
      drivers = [pkgs.stable.epson-escpr];
    };

    # Cron jobs
    cron = {
      enable = true;
      systemCronJobs = [
        "0 0 * * * ${pkgs.bash}/bin/bash -c '${config.users.users.${secrets.username}.home}/.local/bin/rebuild'"
      ];
    };

    # Add Avahi for Samba printing discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
        workstation = true;
      };
    };

    trezord.enable = true;
    samba.enable = true;
  };

  # Automatically configure Flathub repository for all users
  systemd.services.flatpak-repo = {
    wantedBy = ["multi-user.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
    '';
  };

  # Systemd services and timers
  systemd = {
    timers = {
      # weeklyUpdate = {
      #   description = "Weekly NixOS system update";
      #   wantedBy = ["timers.target"];
      #   timerConfig = {
      #     OnCalendar = "weekly";
      #     Persistent = true;
      #   };
      # };
      # monthlyCleanup = {
      #   description = "Monthly NixOS garbage collection";
      #   wantedBy = ["timers.target"];
      #   timerConfig = {
      #     OnCalendar = "monthly";
      #     Persistent = true;
      #   };
      # };
    };
    services = {
      # weeklyUpdate = {
      #   description = "Update NixOS system";
      #   serviceConfig = {
      #     ExecStart = "${pkgs.bash}/bin/bash -c 'for i in {1..3}; do nix flake update && nixos-rebuild switch --flake /etc/nixos && break || sleep 10; done'";
      #     User = "root";
      #   };
      # };
      # monthlyCleanup = {
      #   description = "Clean up old NixOS generations";
      #   serviceConfig = {
      #     ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d";
      #     User = "root";
      #   };
      # };
    };
    sleep.extraConfig = ''
      [Sleep]
      AllowHibernation=no
      AllowHybridSleep=yes
      AllowSuspendThenHibernate=no
    '';
  };

  # Boot settings
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.consoleMode = "auto";
      timeout = 0;
    };
    consoleLogLevel = 0;
    initrd.verbose = false;
    extraModprobeConfig = ''
      options kvm_amd nested=1
      options kvm ignore_msrs=1 report_ignored_msrs=0
    '';
  };

  # Plymouth (boot screen)
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {selected_themes = ["rings"];})
    ];
  };

  # Kernel Parameters
  # boot.kernelPackages = pkgs.linuxPackages_latest; # Uncomment to use latest stable
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=auto"
    # "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];

  # Enable Xbox One driver
  boot.extraModulePackages = [config.boot.kernelPackages.xone];
  boot.kernelModules = [
    "xone"
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "ch343"
  ];

  # udev rules
  services.udev.extraRules = ''
    ACTION=="add", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTRS{address}=="D8:93:67:08:1C:C9", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", SYMLINK+="ttyUSB_CH343G"
  '';

  # Hardware settings
  hardware = {
    steam-hardware.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Power settings
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  # Graphics settings
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:13:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia-container-toolkit.mount-nvidia-executables = true;
  services.xserver.videoDrivers = ["nvidia" "amdgpu"];
  nixpkgs.config.cudaSupport = true;

  # User customizations (KDE services handled by aerotheme/system.nix)
  services.xserver.xkb = {
    layout = "us";
    variant = "colemak";
  };

  # Sound settings
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  # Networking settings
  networking = {
    networkmanager.enable = true;
    hostName = "${secrets.hostName}";
    firewall = {
      allowedTCPPorts = [631]; # CUPS
      allowedUDPPorts = [];
    };
  };

  # Virtualization settings
  # virtualisation = {
  #   docker = {
  #     enable = true;
  #     enableOnBoot = true;
  #     rootless.enable = true;
  #     rootless.setSocketVariable = true;
  #     daemon.settings.features.cdi = true;
  #     extraPackages = with pkgs; [nvidia-container-toolkit nvidia-docker];
  #   };
  #   libvirtd = {
  #     enable = true;
  #     qemu = {
  #       package = pkgs.qemu_kvm;
  #       ovmf = {
  #         enable = true;
  #         packages = [
  #           (pkgs.OVMF.override {
  #             secureBoot = true;
  #             tpmSupport = true;
  #           })
  #         ];
  #       };
  #       swtpm.enable = true;
  #       runAsRoot = true;
  #     };
  #   };
  #   spiceUSBRedirection.enable = true;
  # };

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Nix settings
  nix.settings = {
    sandbox = true;
    experimental-features = "nix-command flakes";
    nix-path = ["nixpkgs=${pkgs.path}"];
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = ["--update-input" "nixpkgs" "-L"];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  nix = {
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
    gc = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  systemd.services.libvirtd = {
    enable = true;
    wantedBy = ["multi-user.target"];
    path = [pkgs.qemu];
  };

  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /home/${secrets.username}/.cloudflared/config.yml run 97f0877b-9ed5-42ba-999e-d13903c05d52";
      Restart = "always";
      User = "${secrets.username}";
      StateDirectory = "cloudflared";
      ConfigurationDirectory = "cloudflared";
      ConfigurationDirectoryMode = "0755";
    };
  };

  # User settings
  users = {
    mutableUsers = false;
    groups.${secrets.username} = {};
    users.${secrets.username} = {
      isNormalUser = true;
      group = "${secrets.username}";
      home = "${secrets.userHome}";
      extraGroups = [
        "${secrets.username}"
        "wheel"
        "networkmanager"
        "lp"
        "scanner"
        "docker"
        "libvirtd"
        "kvm"
        "input"
        "builder"
      ];
      shell = pkgs.bash;
      hashedPassword = "${secrets.hashedPassword}";
      description = "${secrets.description}";
    };
  };

  # Locale and timezone settings
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };
  };

  # Other settings
  system.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
  nix.channel.enable = false;
}
