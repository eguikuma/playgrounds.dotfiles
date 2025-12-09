if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if type -q mise
    mise activate fish | source
end

fish_add_path $PNPM_HOME
fish_add_path $BUN_INSTALL/bin
fish_add_path '/mnt/c/Users/{{WINDOWS_USERNAME}}/AppData/Local/Programs/Microsoft VS Code/bin'

set -gx PNPM_HOME "$HOME/.local/share/pnpm"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx HOMEBREW_CURL_PATH /home/linuxbrew/.linuxbrew/bin/curl
set -gx FZF_DEFAULT_OPTS "
  --prompt='🔎 '
  --inline-info
  --height=40%
  --reverse
  --header=''
  --margin=0,0,0,0
  --padding=1,2
  --pointer=' >'
  --gutter=' '
  --marker='✓'
  --no-hscroll
  --info=inline
  --color=dark
  --color=fg:#c0caf5,bg:-1,hl:#f7768e
  --color=fg+:#ffffff,bg+:#283457,hl+:#f7768e
  --color=prompt:#7aa2f7,pointer:#ffffff,marker:#9ece6a
  --color=info:#7dcfff,spinner:#bb9af7,header:#7aa2f7
  --color=gutter:-1,border:-1
  --bind='ctrl-p:toggle-preview'
  --ellipsis=...
  --tabstop=4
  --preview-window=right:70%:wrap
  --color=gutter:-1,border:#1A1E22
"

set -g fzf_history_opts --prompt='🔎 in:commands > '
set -g fzf_directory_opts --prompt='🔎 in:directories > '
set -g fzf_git_log_opts --prompt='🔎 in:commits > '
set -g fzf_git_status_opts --prompt='🔎 in:changes > '
set -g fzf_processes_opts --prompt='🔎 in:processes > '
set -g fzf_variables_opts --prompt='🔎 in:variables > '
set -g fish_greeting ''
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER explorer.exe
set -gx BROWSER_CMD chrome
set -g GHQ_SELECTOR fzf

alias .. 'cd ..'
alias ... 'cd ../..'
alias cat bat
alias ls 'eza -lha'
alias find fd
alias grep 'rg --color=always --line-number --heading --pretty'
alias diff 'delta -s'
alias man gman
alias mkdir 'mkdir -p'
alias vim nvim
alias vi nvim
