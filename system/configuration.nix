{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  secrets = import ../home/secrets.nix;
in {
  imports = [
    ./system.nix
    ./packages.nix
  ];

  # Hardware-specific settings
  hardware = {
    steam-hardware.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Power settings (hardware-related)
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  # Graphics settings (hardware-specific)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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
  services.xserver.videoDrivers = ["amdgpu" "nvidia"];
  nixpkgs.config.cudaSupport = true;

  # udev rules (hardware-specific)
  services.udev.extraRules = ''
    ACTION=="add", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTRS{address}=="D8:93:67:08:1C:C9", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", SYMLINK+="ttyUSB_CH343G"
  '';
}
