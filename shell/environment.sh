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

# Add bin directory to path
export PATH="$HOME/bin:$HOME/dotfiles/bin:$PATH"

# Add gnubin to PATH
export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH

# Add system-level extra binaries to path
export PATH="/opt/bin:$PATH"

# rbenv
eval "$(rbenv init -)"

# pyenv
if [ "${HOMEBREW_PREFIX:-}" != "" ]; then
  export PYENV_ROOT="$HOMEBREW_PREFIX/opt/pyenv"
else
  export PYENV_ROOT="$HOME/.pyenv"
fi
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

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

# mcfly
export MCFLY_FUZZY=true

# SDKMAN! -- See https://sdkman.io/usage
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
