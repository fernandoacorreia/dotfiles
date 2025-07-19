# Source profile for login shells
source ~/.profile

# gvm (Go Version Manager) - moved from .zshrc
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# zoxide (must be done after gvm setup to avoid conflict with the cd command)
if command -v zoxide >/dev/null 2>&1 && [ -n "$ZSH_VERSION" ]; then
  eval "$(zoxide init zsh --cmd cd)"
fi
