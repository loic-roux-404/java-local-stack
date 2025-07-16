#!/usr/bin/env fish

set -gx SSHPASS (printf '%s' (cat ~/.config/.sshpass || echo -n ''))
set -gx PATH "$PATH:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin"

# create alias
function coam
	git add .
	git commit -m $argv
end

function cloam
	git add .
	git commit -m $argv
	git push
end

function switch-user
	git config user.name $argv[1]
	git config user.email $argv[2]
end

alias gst="git status"
alias gp="git push"

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

function fbr
    git fetch origin $argv:$argv
end

function pte
	tree -L $argv -u -g -p -d
end

function gd
	git diff
end

function gcoam-f
	git add --update
	git commit --amend --no-edit
	git push --force-with-lease
end

function gcoam
	git add --update .
	git commit --amend
	git push --force-with-lease
end

function del-branch
	git push -d origin $argv && git branch -d $argv
end

function fetchPt
	git fetch origin "refs/heads/$argv[1]*:refs/remotes/$argv[1]/$argv[2]*"
end

function to-gateway
        set src $argv[1]
        set dest $argv[2]
        sshpass -e rsync -avzh $src gateway:$dest
end

function sshp
    sshpass -e ssh $argv
end

function rsyncp
    sshpass -e rsync $argv
end

function scpp
	sshpass -e scp $argv
end

function ssh_close
    set -lx ctrl_path "/tmp/ssh_mux_$argv[1]"
    sshp -o ControlPath=$ctrl_path -O exit gateway
end

function ssh_proxy
    if test -z $SSHPASS
        echo "need ssh password at ~/.config/.sshpass"
        exit 1
    end

    echo "Starting ssh tunnel for $argv[1]:$argv[2] ..."
    set -lx ctrl_path "/tmp/ssh_mux_$argv[2]"

    sshp -o ControlMaster=auto -o ControlPath=$ctrl_path -o ControlPersist=yes \
     -f -N -L "$argv[2]:$argv[1]:$argv[2]" $argv[3]
end

# Theme
set -g theme_nerd_fonts yes

set --universal -x WIN_PATH /mnt/c/Users/$USER

timeout 15 bash -c "while [ ! -e '/nix/var/nix/daemon-socket/socket' ]; do sleep 1; done"

direnv hook fish | source
direnv export fish | source
