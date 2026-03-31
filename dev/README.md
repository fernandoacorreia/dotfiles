Helpers for developing and testing dotfiles.

## Scripts

All scripts are run from the repo root.

```
dev/build              # build the container image
dev/run                # mount dotfiles at ~/dotfiles (default)
dev/run --bare         # mount at /mnt/dotfiles with a clean home directory
dev/test               # run the full setup inside a container (output saved to dev/.output/)
```
