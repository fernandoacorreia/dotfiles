# fzf
export FZF_DEFAULT_OPTS="--history=$HOME/.fzf_history"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# less command options
export LESS='--quit-if-one-screen --no-init --RAW-CONTROL-CHARS'

# sbt
export SBT_OPTS="-Xss256m -Xmx6g"

# zsh vi mode
# https://dougblack.io/words/zsh-vi-mode.html
bindkey -v
export KEYTIMEOUT=1

# neovim
export EDITOR=nvim

# Add bin directories to path
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/dotfiles/bin:/opt/bin:/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# rbenv
eval "$(rbenv init -)"

# keychain
# See https://www.funtoo.org/Keychain
# See https://unix.stackexchange.com/a/90869/56711
if command -v keychain &>/dev/null; then
  eval `keychain --eval --agents ssh id_ed25519`
fi

# linuxbrew
if [ -f $HOME/.linuxbrew/bin/brew ]; then
  eval $($HOME/.linuxbrew/bin/brew shellenv)
fi
