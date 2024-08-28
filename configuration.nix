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
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
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
    docker-compose
    mono
    p7zip
    unrar
    unzip
    python3
    exfatprogs

    #LLM
    python312Full
    # python311Packages.bentoml
    # python311Packages.openllm
    # python311Packages.gradio

    # Wine
    wineWowPackages.unstableFull
    wineWow64Packages.unstableFull
    wineWowPackages.waylandFull
    wineWow64Packages.waylandFull
    wineWowPackages.fonts
    wineWow64Packages.fonts
    winetricks

    # Hardware
    vulkan-tools
    vulkan-headers
    dxvk
    epson-escpr # my printer
    pciutils
    glxinfo
    lshw

    # KDE
    kdeplasma-addons
    kdePackages.sddm-kcm
    kdePackages.yakuake
    kdePackages.skanlite
    kdePackages.kdenlive
    kdePackages.okular
    kdePackages.kmail
    kdePackages.elisa
    kdePackages.kcalc
    kdePackages.ksystemlog
    kdePackages.kolourpaint
    kdePackages.isoimagewriter
    plasma-browser-integration
    kdePackages.qtstyleplugin-kvantum
    kdePackages.partitionmanager

    # Package derivation template
    (writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Mountain/contents/images_dark/5120x2880.png
    '')
  ];

  # Services settings
  services = {
    flatpak.enable = true;
    printing.enable = true;

    # Cron jobs
    cron = {
      enable = true;
      systemCronJobs = [
        "0 0 * * 1 ${pkgs.bash}/bin/bash -c '${config.users.users.${secrets.username}.home}/.local/bin/rebuild'"
      ];
    };
  };

  # Systemd services
  # systemd.services.huggingchat = {
  #   script = ''
  #     docker-compose -f ${secrets.userHome}/dev/docker-compose/huggingchat.yml up
  #   '';
  #   wantedBy = ["multi-user.target"];
  #   after = ["docker.service" "docker.socket"];
  # };

  # Boot settings
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    consoleLogLevel = 0;
    initrd.verbose = false;
    loader.timeout = 0;
  };

  # Plymouth (boot screen)
  boot.plymouth = {
    enable = true;
    theme = "rings";
    # To only install one theme:
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {
        selected_themes = ["rings"];
      })
    ];
  };

  # Kernel Parameters
  boot.kernelParams = [
    # "nvidia_drm.modeset=1" # Enable DRM kernel mode setting
    # "nvidia_drm.fbdev=1" # Fix phantom monitor issue (I have a 3060 Ti)
    # "nvidia.NVreg_EnableGpuFirmware=0" # Disable GSP (GPU offloading) to fix Wayland performance
    # "mem_sleep_default=shallow" # Fix sleep issues
    # "acpi_osi=!"
    "acpi_osi=Linux"
    # "acpi_sleep=s4_nohwsleep" # alternate sleep fix
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];

  # udev rules
  services.udev.extraRules = ''
    ACTION=="add", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
  ''; # Disable USB mouse wake up because my fucking logitech mouse randomly wakes up computer

  # Hardware settings
  hardware = {
    steam-hardware.enable = true;
    pulseaudio.enable = false;
  };

  # Graphics settings
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true; # use kernel param instead
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    prime = {
      sync.enable = false;
      offload.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:13:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
  };
  # hardware.nvidia-container-toolkit.enable = true; # docker usage
  # hardware.nvidia-container-toolkit.mount-nvidia-executables
  services.xserver.videoDrivers = ["nvidia" "amdgpu"];

  # KDE
  services.desktopManager.plasma6.enable = true;
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "colemak";
    };
  };
  services.displayManager.sddm = {
    wayland.enable = true;
    enable = true;
    settings = {
      General = {
        # GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=0.75";
      };
    };
    extraPackages = with pkgs; [];
  };

  # Sound settings
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true; # PipeWire pulse audio service
  };

  # Networking settings
  networking = {
    networkmanager.enable = true;
    hostName = "${secrets.hostName}";
    firewall = {
      allowedTCPPorts = [
        631 # CUPS
      ];
      allowedUDPPorts = [
      ];
    };
  };

  # Docker settings
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
    rootless.enable = true;
    rootless.setSocketVariable = true;
    daemon.settings = {
      default-runtime = "nvidia";
      # runtimes.nvidia.path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
    };
    extraPackages = with pkgs; [
      nvidia-container-toolkit
    ];
  };

  # Virtualization settings
  virtualisation.libvirtd.enable = true;

  # User settings
  users = {
    mutableUsers = false; # Ensure users are managed declaratively
    users = {
      ${secrets.username} = {
        isNormalUser = true;
        home = "${secrets.userHome}";
        extraGroups = [
          "wheel"
          "networkmanager"
          "lp"
          "scanner"
          "docker"
          "libvirtd"
        ];
        shell = pkgs.bash;
        hashedPassword = "${secrets.hashedPassword}";
        description = "${secrets.description}";
      };
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
  nix = {
    settings.experimental-features = "nix-command flakes";
    settings.nix-path = ["nixpkgs=${pkgs.path}"];
    channel.enable = false;
  };
}
