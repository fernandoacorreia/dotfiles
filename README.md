# dotfiles

Machine setup.

## Supported OSes

- macOS Monterey or Ventura on Apple silicon
- Ubuntu 20.04.2 LTS Focal Fossa

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
