# Homebrew paths
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Import secrets
if test -n "$(find ~/secrets -maxdepth 1 -name '*.sh' -print -quit)"  # https://stackoverflow.com/a/7702334
then
  for f in ~/secrets/*.sh; do source $f; done
fi

source $HOME/dotfiles/shell/environment.sh
source $HOME/dotfiles/shell/aliases.sh
source $HOME/dotfiles/shell/less-termcap.sh

# Support a local profile script that's not saved to source control.
if test -f $HOME/.local_profile
then
  source $HOME/.local_profile
fi
