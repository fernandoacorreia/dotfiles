# dotfiles

Machine setup.

## Supported OSes

- macOS Ventura on Apple silicon
- LMDE 6 "Faye" (Linux Mint Debian Edition) - Debian 12 (bookworm)

## Installing

To download and install, run this command:

```
curl https://raw.githubusercontent.com/fernandoacorreia/dotfiles/main/setup -o /tmp/dotfiles-setup
bash /tmp/dotfiles-setup
```

If you don't have an ssh key, one will be generated. When prompted, add it to your [GitHub settings](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/) and re-run the same command again:

```
bash /tmp/dotfiles-setup
```

## Updating

```
cd ~/dotfiles
git pull
git submodule update --init --recursive
./setup
```
