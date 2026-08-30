# zdt's dotfiles

Nix + Home Manager configurations for Linux and macOS.

## Profiles

Configurations are named `zdt@{arch}-{os}-{profile}`. Profiles are cumulative:

| Profile    | Contents                                                                    |
|------------|-----------------------------------------------------------------------------|
| `minimal`  | coreutils, curl, wget, fd, ripgrep, vim, git, gh, starship, direnv           |
| `headless` | minimal + claude-code / codex / grok, cmake, gcc, node, python, mosh, LSP servers |
| `full`     | headless + emacs, OCaml, Rust, qemu, gdb/pwndbg/valgrind, wireshark |

```
zdt@x86_64-linux-full     zdt@x86_64-linux-headless    zdt@x86_64-linux-minimal
zdt@aarch64-linux-full    zdt@aarch64-linux-headless   zdt@aarch64-linux-minimal
zdt@aarch64-darwin-full   zdt@aarch64-darwin-headless  zdt@aarch64-darwin-minimal
```

## Layout

```
flake.nix                  inputs + the homeConfigurations matrix
switch.sh                  detects arch+OS, activates the right configuration
home/
  default.nix              home-manager entry point (env, XDG, doom link)
  packages.nix             the package set, split by profile
  programs.nix             git, gh, bash, starship, direnv, tmux, ssh
  python-packages.nix      the python3 that lands on PATH
  haskell-packages.nix     ghcWithPackages
emacs/doom/                doom config, symlinked to ~/.config/doom
```

## Install

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon   # if nix isn't installed
git clone git@github.com:ZeroDayTea/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./switch.sh
```

## Usage

```sh
./switch.sh                  # rebuild and activate (full profile)
./switch.sh headless         # activate a different profile
nix flake update             # bump nixpkgs / home-manager / pwndbg
home-manager generations     # list generations
```
