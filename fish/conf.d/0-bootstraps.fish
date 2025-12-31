if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if type -q mise
    mise activate fish | source
end

if status is-interactive
    stty -ixon
    printf '\e[5 q'
end
