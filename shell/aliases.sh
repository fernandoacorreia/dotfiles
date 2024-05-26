# Git
alias gcd='git checkout develop'
alias gco='git checkout'
alias gfa='git fetch --all --tags --prune'
alias gg='git grep'
alias gl='git pull'
alias gpf='git push -f origin HEAD'
alias gpu='git push -u origin HEAD'
alias gst='git status'

# Color in diff and grep
alias diff="colordiff"
alias grep="grep --color=always"

# Kubernetes
alias k='kubectl'

# Enable alias expansion with watch
alias watch='watch '  # https://unix.stackexchange.com/a/25329/56711

# Neovim
alias vi='nvim'

# Tmux
alias tmux='TERM=xterm-256color tmux'

# Clear screen (when Ctrl+L is remapped)
alias cls=clear

# Podman / Docker
alias docker=podman
