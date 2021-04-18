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
export PATH="$HOME/dotfiles/bin:$PATH"

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
