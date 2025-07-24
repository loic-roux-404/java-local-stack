{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz") {} }: {
  base = import ./nix-base/shell.nix { inherit pkgs; };
  stack = import ./stack/default.nix { inherit pkgs; };
  nixpkgslegacy2211 = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz") {
    config.permittedInsecurePackages = [
      "nodejs-14.21.1"
    ];
  };
  nixpkgslegacy2311 = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/23.11.tar.gz") {
    config.allowUnfree = true;
    config.permittedInsecurePackages = [
      "python-2.7.18.7"
    ];
  };
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz") { };
}
