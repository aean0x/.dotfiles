{
  pkgs ?
    import <nixpkgs> {
      config.allowUnfree = true;
    },
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
    python3Packages.torchWithCuda
    python3Packages.torchvision
    python3Packages.pillow
    python3Packages.face-recognition
    python3Packages.numpy
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
  ];
}
