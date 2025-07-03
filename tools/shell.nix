{
  pkgs ?
    import <nixpkgs> {
      config.allowUnfree = true;
    },
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
    python312Packages.torchWithCuda
    python312Packages.torchvision
    python312Packages.pillow
    python312Packages.face-recognition
    python312Packages.numpy
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
  ];
}
