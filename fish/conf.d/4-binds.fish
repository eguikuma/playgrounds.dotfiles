source ~/.config/fish/functions/github.fish

bind \cd ''
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \cd ''
end

bind \cg '__ghq_repository_search github'
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \cg '__ghq_repository_search github'
end

bind \ca '__ghq_repository_search archive.github'
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \ca '__ghq_repository_search archive.github'
end
