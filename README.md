# zdt's dotfiles

## nix

Run from `nixos/`:

```sh
nix flake update               # bump flake inputs (nixpkgs, etc.)
nix profile add .              # install env into user profile
nix profile upgrade nixos      # rebuild after editing flake.nix or `nix flake update`
nix profile remove nixos       # uninstall
```

## doom

Symlink the config, then sync:

```sh
ln -sfn ~/dotfiles/emacs/doom ~/.config/doom
~/.config/emacs/bin/doom sync     # full path may be needed if doom isn't on PATH yet
~/.config/emacs/bin/doom upgrade
```
