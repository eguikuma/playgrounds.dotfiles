set -gx PNPM_HOME "$HOME/.local/share/pnpm"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx HOMEBREW_CURL_PATH /home/linuxbrew/.linuxbrew/bin/curl
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx VIMRUNTIME /home/linuxbrew/.linuxbrew/opt/neovim/share/nvim/runtime
set -gx BROWSER explorer.exe
set -gx DEFAULT_BROWSER chrome
set -g GHQ_SELECTOR fzf

set -gx FZF_DEFAULT_OPTS "
  --prompt='🐟 '
  --inline-info
  --height=40%
  --reverse
  --header=''
  --margin=0,0,0,0
  --padding=1,2
  --pointer=''
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

set -g fish_greeting ''
set -g fzf_history_opts --prompt='🐟 select:commands > '
set -g fzf_directory_opts --prompt='🐟 select:directories > '
set -g fzf_git_log_opts --prompt='🐟 select:commits > '
set -g fzf_git_status_opts --prompt='🐟 select:changes > '
set -g fzf_processes_opts --prompt='🐟 select:processes > '
set -g fzf_variables_opts --prompt='🐟 select:variables > '
