# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

DEFAULT_USER=$(whoami)

source $HOME/dotfiles/vendor/antigen/antigen.zsh
antigen use oh-my-zsh

antigen bundle git
antigen bundle command-not-found
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen theme romkatv/powerlevel10k # https://github.com/romkatv/powerlevel10k#antigen

antigen apply

# kubectl completion
if test -f kubectl; then
  source <(kubectl completion zsh)
fi

source ~/.profile

# Setup fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# https://github.com/cantino/mcfly
if command -v mcfly &>/dev/null; then
  export MCFLY_FUZZY=2
  export MCFLY_KEY_SCHEME=vim
  export MCFLY_RESULTS=30
  eval "$(mcfly init zsh)"
fi

# sdkman-init.sh is loaded in environment.sh

# gvm (Go Version Manager)
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# zoxide
eval "$(zoxide init zsh --cmd cd)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

function update_gpg_tty() {
  # Makes sure that GPG will prompt for a password in the correct TTY device.
  # It's useful for Git operations that require GPG signing, like signed commits.
  export GPG_TTY=$(tty)
  if [ -n "$TMUX" ]; then
    # Tmux creates a more complex terminal environment with multiple virtual TTYs,
    # and it maintains a persistent session that can detach/reattach.
    # updatestartuptty is a command that tells the GPG agent which TTY to use for pinentry (password prompt).
    # When switching to a previous Tmux window or pane, it might be necessary to re-run this command manually.
    gpg-connect-agent updatestartuptty /bye >/dev/null
  fi
}

# Add our function to precmd hooks.
precmd_functions+=(update_gpg_tty)

# fnm - Fast and simple Node.js version manager
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi
