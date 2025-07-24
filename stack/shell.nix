{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz") {
    config = {
      allowUnfree = true;
    };
  }
}:
let
  envs = (import (builtins.fetchTarball {
    url = "https://github.com/loic-roux-404/java-local-stack/-/archive/develop/ti-local-stack-develop.tar.gz";
  }) { inherit pkgs; });
in (envs.base.overrideAttrs (old: {
  buildInputs = with pkgs; old.buildInputs ++ envs.ti.buildInputs ++ [
    envs.unstable.semeru-bin
    maven
    nodejs
    glab
  ];

  postShellHook = old.postShellHook + envs.ti.tiShellHook + ''
    export JAVA_HOME_LS=${envs.unstable.semeru-bin}
  '';

  postVenvCreation = old.postVenvCreation + envs.ti.install + ''
    export JAVA_HOME_LS=${envs.unstable.semeru-bin}
    make vscode-configs idea-configs generate-vscode-workspace &>/dev/null
  '';
}))
