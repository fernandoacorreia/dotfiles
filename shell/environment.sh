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

# SDKMAN! -- See https://sdkman.io/usage
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# nvm - see https://github.com/nvm-sh/nvm?tab=readme-ov-file#install--update-script
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

