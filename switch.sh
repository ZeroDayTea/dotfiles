#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

# a fresh machine has no flakes in nix.conf yet; this repo is what installs it
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

die() { echo "error: $*" >&2; exit 1; }

command -v nix >/dev/null 2>&1 ||
  die "nix is not installed. See https://nixos.org/download/ then re-run ./switch.sh"

case "$(uname -s)" in
  Linux)  OS="linux" ;;
  Darwin) OS="darwin" ;;
  *) die "unsupported OS $(uname -s)" ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  ARCH="x86_64" ;;
  arm64|aarch64) ARCH="aarch64" ;;
  *) die "unsupported architecture $(uname -m)" ;;
esac

PROFILE="${1:-}"
case "$PROFILE" in
  minimal|headless|full) shift ;;
  *) PROFILE="${DOTFILES_PROFILE:-full}" ;;
esac

USER_NAME="$(id -un)"
TARGET="${USER_NAME}@${ARCH}-${OS}-${PROFILE}"

# home/default.nix hardcodes ~/dotfiles for the doom symlink
if [ "$REPO" != "$HOME/dotfiles" ]; then
  die "this repo must live at ~/dotfiles (found: $REPO).
       Either move it there, or change dotfilesDir in home/default.nix."
fi

# home-manager asserts USER and HOME match the configuration at activation
AVAILABLE="$(nix "${NIX_FLAGS[@]}" eval --raw .#homeConfigurations \
  --apply 'cs: builtins.concatStringsSep "\n" (builtins.attrNames cs)' 2>/dev/null || true)"

if [ -n "$AVAILABLE" ] && ! grep -qx "$TARGET" <<<"$AVAILABLE"; then
  echo "error: no configuration named '$TARGET'." >&2
  echo >&2
  if ! grep -q "^${USER_NAME}@" <<<"$AVAILABLE"; then
    echo "       This machine's username is '${USER_NAME}', but the flake only" >&2
    echo "       defines configurations for other users. Set" >&2
    echo "           username = \"${USER_NAME}\";" >&2
    echo "       near the top of flake.nix (or add a second entry there)." >&2
  else
    echo "       Available:" >&2
    sed 's/^/         /' <<<"$AVAILABLE" >&2
  fi
  exit 1
fi

# the old env installs the same binaries into ~/.nix-profile; they collide
if nix "${NIX_FLAGS[@]}" profile list 2>/dev/null | grep -q "zdt-dev-env"; then
  die "the legacy \`nix profile\` environment is still installed and will
       collide with home-manager over ~/.nix-profile. Remove it first:

           nix profile remove nixos

       (or: nix profile list, then remove it by index), then re-run ./switch.sh"
fi

# a hand-made symlink here blocks the one home-manager creates; its own
# link points into /nix/store and must be left alone
if [ -L "$HOME/.config/doom" ] && [[ "$(readlink "$HOME/.config/doom")" != /nix/store/* ]]; then
  echo "note: replacing the hand-made ~/.config/doom symlink" >&2
  rm "$HOME/.config/doom"
fi

# ~/.config/doom takes precedence, so a repo-pointing ~/.doom.d is now dead
if [ -L "$HOME/.doom.d" ] && [ "$(readlink "$HOME/.doom.d")" = "$REPO/emacs/doom" ]; then
  echo "note: removing the now-redundant ~/.doom.d symlink" >&2
  rm "$HOME/.doom.d"
fi

# git reads ~/.gitconfig after ~/.config/git/config, so a leftover one wins
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
  echo "warning: ~/.gitconfig shadows the home-manager git config; delete it" >&2
fi

echo ">> switching to ${TARGET}"

# -b backup moves a pre-existing ~/.bashrc etc. aside instead of refusing to run
if command -v home-manager >/dev/null 2>&1; then
  exec home-manager switch --flake ".#${TARGET}" -b backup "$@"
else
  echo ">> home-manager not on PATH, bootstrapping the version in flake.lock"
  exec nix "${NIX_FLAGS[@]}" run .#home-manager -- \
    switch --flake ".#${TARGET}" -b backup "$@"
fi
