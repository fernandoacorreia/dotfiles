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

source ~/.zprofile

# Setup fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# https://github.com/cantino/mcfly
if command -v mcfly &>/dev/null; then
  export MCFLY_FUZZY=2
  export MCFLY_KEY_SCHEME=vim
  export MCFLY_RESULTS=30
  eval "$(mcfly init zsh)"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# fnm - Fast and simple Node.js version manager
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

