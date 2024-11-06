# Git
alias gcd='git checkout develop'
alias gco='git checkout'
alias gfa='git fetch --all --tags --prune'
alias gg='git grep'
alias gl='git pull'
alias gpf='git push -f origin HEAD'
alias gpu='git push -u origin HEAD'
alias gst='git status'

# Color output
alias diff="colordiff"
alias grep="grep --color=auto"
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ls='ls --color=auto'

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

# Check if podman is installed
if command -v podman &> /dev/null
then
    # Create alias for docker to podman
    alias docker='podman'
fi

