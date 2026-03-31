Helpers for developing and testing dotfiles.

## debian-container

Launches a fresh, ephemeral Debian Trixie container with dotfiles mounted.

```
dev/debian-container          # mount dotfiles at ~/dotfiles (default)
dev/debian-container --bare   # mount at /mnt/dotfiles with a clean home directory
```
