{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz") {
    config = {
      allowUnfree = true;
    };
  }
}:

let
  python = pkgs.python311;
  pythonPackages = python.pkgs;
  current_dir = builtins.toString ./.;
  ARTIFACTORY_auth = ''
    export ARTIFACTORY_USER="$(cat ~/.config/.artifactory-user)"
    export ARTIFACTORY_TOKEN="$(cat ~/.config/.artifactory-token)"
    echo "Ready to log in to nexus with $ARTIFACTORY_USER"
  '';
  npm_env_setup = ARTIFACTORY_auth + ''
    NPM_AUTH="$(echo -n "$ARTIFACTORY_USER:$ARTIFACTORY_TOKEN" | base64 -w0)"
    NPM_REGISTRY="''${NPM_REGISTRY:-artifactory.pictet.com}"
    NPM_REPO=fpl-ti-npm-group

    export npm_config_prefix=~/.npm-global-$(node -v | cut -d. -f1)
    export npm_config_registry=https://$NPM_REGISTRY/repository/$NPM_REPO/
    mkdir -p $npm_config_prefix/bin || true
    export npm_config_strict_ssl=false

    cat << EOF > ~/.npmrc
registry=$npm_config_registry
//$NPM_REGISTRY/repository/$NPM_REPO/:_auth=$NPM_AUTH
always-auth=true
EOF

    export PNPM_HOME="$npm_config_prefix/bin"
    export PATH="$PATH:$PNPM_HOME"
    echo "Npm set up for $NPM_REGISTRY done"
  '';
in
pkgs.mkShell rec {
  packages = with pkgs; [
    xclip
    sshpass
    rsync
    yq-go
    jq
    kubectl
    kubernetes-helm
    terraform
    terraform-ls
    tree
  ];

  buildInputs = with pkgs; [
    pythonPackages.python
    pythonPackages.pip
    pythonPackages.lxml
    pythonPackages.virtualenv
    pythonPackages.venvShellHook
  ];

  nativeBuildInputs = with pkgs; [
    docker-client
    gnumake
    go
  ];

  venvDir = "./.venv";

  postVenvCreation = ''
    unset SOURCE_DATE_EPOCH

    sudo sed -i '/# NVM/,+2d' ~/.zshrc
    sudo sed -i '/# NVM/,+2d' ~/.bashrc
    sudo sed -i '/# SDKMAN/,+3d' /etc/zsh/zshrc
    sudo sed -i '/# SDKMAN/,+3d' /etc/bash.bashrc

    cat << EOF > ~/.gitignore
.venv
.run
.vscode
app.log
node_modules
nohup.out
target/
.settings
.classpath
.project
*.code-workspace
hiera
giservices
EOF
    git config core.filemode false || true
    git config --global core.filemode false
    git config --global core.excludesFile ~/.gitignore
    git config --global core.autocrlf false

    ssh-keyscan git.pictet.com >> ~/.ssh/known_hosts || true
    ssh-keyscan github.com >> ~/.ssh/known_hosts || true

    mkdir -p ~/.config/
    if [ ! -f ~/.config/.artifactory-user ]; then
      echo "Enter your kazan user, taken from (https://artifactory.pictet.com/#user/usertoken)"
      read -r user; echo "$user" > ~/.config/.artifactory-user
    fi

    if [ ! -f ~/.config/.artifactory-token ]; then
      echo "Enter your kazan token, taken from (https://artifactory.pictet.com/#user/usertoken)"
      read -r token; echo "$token" > ~/.config/.artifactory-token
    fi

  '' + npm_env_setup;

  postShellHook = ''
    unset SOURCE_DATE_EPOCH

    export NODE_OPTIONS=--max-http-header-size=256000

    export GOPATH=$(go env GOPATH)
    export GOBIN=$GOPATH/bin

    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'

    alias stack="make --no-print-directory -C $PWD"

    function pte() {
      tree -L $@ -u -g -p -d
    }
  '' + npm_env_setup;
}
