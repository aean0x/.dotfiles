{pkgs, ...}: {
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
    bottles
    picocom
    neofetch
    openvpn3
    sops
    tree
    flatpak
    epson-escpr2
    epsonscan2
    desktop-file-utils

    # Development
    # nixd
    androidenv.androidPkgs.platform-tools

    # Flatpak management
    # gnome-software

    # Build tools
    # cmake
    # dlib
    # bison
    # flex
    # fontforge
    # makeWrapper
    # pkg-config
    # gnumake
    # libiconv
    # autoconf
    # automake
    # libtool
    # ninja
    # libgcc
    # gcc
    # libGL
    # mesa
    # libglvnd

    # VM/KVM tools
    # docker-compose
    # qemu
    # OVMF
    # spice
    # spice-gtk
    # spice-protocol
    # virt-viewer
    # libguestfs
    # bridge-utils
    # seabios
    # dmg2img
    # tesseract
    # screen

    # oops all global packages
    # cudaPackages.cudatoolkit
    # cudaPackages.cudnn
    # python312
    # python312Packages.torch-bin
    # python312Packages.pybind11
    # python312Packages.pip
    # python312Packages.dlib
    # python312Packages.tensorflow-bin

    # Wine
    wineWow64Packages.fonts
    wineWow64Packages.waylandFull
    winetricks

    # Hardware
    vulkan-tools
    vulkan-headers
    dxvk
    pciutils
    mesa-demos
    lshw
  ];
}
