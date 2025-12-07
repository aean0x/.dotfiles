{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/980f765d-b3c6-48e4-9413-8e951d896f94";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F063-E0C7";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # fileSystems."/mnt/data" = {
  #   device = "/dev/disk/by-uuid/aa1fb32b-1a06-44be-9d7b-e304b71326d5";
  #   fsType = "ext4";
  #   options = ["defaults" "noatime"];
  # };

  swapDevices = [
    {device = "/dev/disk/by-uuid/ddaa3b23-f4f6-490e-92a9-24fb2ec9fe5b";}
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
