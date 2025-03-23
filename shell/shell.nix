{pkgs ? import <nixpkgs> {}}: let
  target = pkgs.pkgsCross.aarch64-multiplatform;
in
  target.mkShell {
    buildInputs = [
      target.gcc
      target.zlib
      # Add other dependencies as needed
    ];
    nativeBuildInputs = [
      pkgs.pkg-config
      # Add other native build tools if required
    ];
  }
