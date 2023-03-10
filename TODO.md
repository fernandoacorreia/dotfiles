Old path:
/home/ec2-user/.nvm/versions/node/v14.19.1/bin:/home/ec2-user/.pyenv/shims:/home/ec2-user/.pyenv/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

New path:
/home/linuxbrew/.linuxbrew/opt/pyenv/shims:/home/linuxbrew/.linuxbrew/opt/pyenv/bin:/home/ec2-user/.rbenv/shims:/opt/bin:/usr/local/opt/coreutils/libexec/gnubin:/home/ec2-user/bin:/home/ec2-user/dotfiles/bin:/home/ec2-user/.pyenv/shims:/home/ec2-user/.pyenv/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.antigen/bundles/robbyrussell/oh-my-zsh/lib:/home/ec2-user/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git:/home/ec2-user/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found:/home/ec2-user/.antigen/bundles/zsh-users/zsh-completions:/home/ec2-user/.antigen/bundles/zsh-users/zsh-syntax-highlighting:/home/ec2-user/.antigen/bundles/zsh-users/zsh-autosuggestions:/home/ec2-user/.antigen/bundles/romkatv/powerlevel10k:/home/ec2-user/.fzf/bin

"node" does not work.

Error: pyenv: no such command `virtualenv-init'


- Finish setting up McFly
- Install Meslo nerd font:
  https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
  - nerd fonts: https://github.com/ryanoasis/nerd-fonts
- p10k configure
  - customize zsh prompt to display hostname and timestamp
- why is become_option=True and not 'yes'?
- incorporate tools from homefiles
- incorporate tools from fedora-setup
- nvim-miniyank
- Ag support in neovim
- gnubin
  - check "Add gnubin to PATH" in environment.sh (and only add it if on macOS)
- golang -- see https://github.com/fernandoacorreia/macfiles/blob/master/shell/environment.sh#L28-L31
- .gitconfig template
- stern zsh completions have been installed to: /opt/homebrew/share/zsh/site-functions
- Neovim: LUA support
  - https://crispgm.com/page/neovim-is-overpowering.html
  - https://oroques.dev/notes/neovim-init/
  - https://github.com/varbhat/dotfiles/tree/main/dot_config/nvim
  - https://gitlab.com/yorickpeterse/dotfiles/-/tree/master/dotfiles/.config/nvim
  - https://github.com/mjlbach/defaults.nvim
- Neovim: Telescope
  - https://crispgm.com/page/neovim-is-overpowering.html
  - https://github.com/nvim-telescope/telescope.nvim
- ~/.ssh/config template
- install podman and alias to docker
- https://zaiste.net/posts/shell-commands-rust/
