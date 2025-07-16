{ pkgs ? import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz") {
    config = {
      allowUnfree = true;
    };
  }
}:
let
  envs = import (builtins.fetchTarball {
    url = "https://gitlab.kazan.myworldline.com/lroux/ti-local-stack/-/archive/develop/ti-local-stack-develop.tar.gz";
  }) { inherit pkgs; };
in (envs.base.overrideAttrs (old: {
  buildInputs = with pkgs; old.buildInputs ++ [
    envs.unstable.semeru-bin
    maven
    (yarn.override { nodejs = nodejs_18; })
    nodejs_18
    nmap
    python311Packages.pandas
  ];
  postVenvCreation = old.postVenvCreation + ''
    mkdir -p ~/.config/gtk-3.0/
    echo -e "[Settings]\ngtk-application-prefer-dark-theme=1" > ~/.config/gtk-3.0/settings.ini

    yarn add global meta
  '';
}))
