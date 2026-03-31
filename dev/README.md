Helpers for developing and testing dotfiles.

## Scripts

All scripts are run from the repo root. Platform is auto-detected
(linux/amd64 on macOS, native on Linux) but can be overridden with
`--platform`.

```
dev/build                          # build the container image
dev/run                            # mount dotfiles at ~/dotfiles (default)
dev/run --bare                     # mount at /mnt/dotfiles with a clean home directory
dev/test                           # run the full setup inside a container (output saved to dev/.output/)
dev/build --platform linux/arm64   # build for a specific platform
```
