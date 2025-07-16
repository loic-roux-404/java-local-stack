{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz") {
    config = {
      allowUnfree = true;
    };
  }
}:
rec {
  folder = pkgs.stdenv.mkDerivation {
    name = "copy";
    src = ./.;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp -rfp $src/* $out
      cp -rfp $src/.* $out
    '';
  };
  repoMapping = ''
    declare -A repo_mapping

    repo_mapping["abc"]=abc-group

    CUST=$(basename $PWD | sed 's/pictet-//g' | sed 's/-meta//g')
  '';
  mvnGenSettings = let
    settingsXml =  pkgs.writeText "settings.xml" (builtins.readFile ./nix-resources/settings.xml);
    patchSettingsPy = pkgs.writeText "settings-patch.py" (builtins.readFile ./nix-resources/settings-patch.py);
  in repoMapping + ''
      echo -n "Set up maven repo " && echo ''${repo_mapping["$CUST"]};
      export MVN_SETTINGS="$HOME/.m2/settings''${CUST:-default}.xml"
      mkdir -p $HOME/.m2 && touch $MVN_SETTINGS || true
	    cp -f ${settingsXml} $MVN_SETTINGS;
      INCLUDED_IDS=''${repo_mapping["$CUST"]} MVN_SETTINGS=$MVN_SETTINGS python3 ${patchSettingsPy};
      export MAVEN_ARGS="-s $MVN_SETTINGS"
    '';
  install = repoMapping + ''
    cat << EOF > .git/info/exclude
.cnf
.make
.docker-compose
.share
nix-resources
Makefile
docker-compose.yml
.env
shell.nix
default.nix
.envrc

EOF

    if [[ ! -v $repo_mapping[$CUST] ]]; then
      echo "Init meta folder project $CUST"

      [[ ! -f ".env" ]] && echo "Create .env from .cnf/.env.$CUST" && \
        cp -f ${folder}/.cnf/.env.$CUST .env || true;
    fi

    exclude='-path "*/node_modules/*" -o -path "*/.git/*" -o -path "*/target/*" -o -path "*/dist/*" -type d -prune'

    function script_rights {
      eval "find . -maxdepth 3 -type f -not \\( $exclude -o -path '*/ti-*/*' \\) -name '*.sh' -exec chmod +x {} \;"
    }

    cp -rfp ${folder}/Makefile .
    cp -rfp ${folder}/docker-compose.yml .
    cp -rfp ${folder}/.* .
    cp -rfp ${folder}/nix-resources .

    chown -R $USER:$USER .
    chmod -R a=r,u+w,a+X .
    script_rights
  '';
  buildInputs = with pkgs; [
    mitmproxy
    ungoogled-chromium
    puppet-lint
    pop
    awscli2
  ];
  tiShellHook = ''
  '';
}
