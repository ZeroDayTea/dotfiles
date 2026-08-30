{ config, lib, pkgs, inputs, username, profile, genericLinux, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux system;

  # a flake cannot know its own checkout path, so this is a convention
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";

  isFull = profile == "full";
  isMinimal = profile == "minimal";
in
{
  imports = [ ./programs.nix ];

  _module.args = { inherit isDarwin isLinux isFull isMinimal dotfilesDir; };

  assertions = [{
    assertion = builtins.elem profile [ "minimal" "headless" "full" ];
    message = "profile must be one of minimal, headless, full (got: ${profile})";
  }];

  home.username = username;
  home.homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  home.packages = import ./packages.nix {
    inherit lib pkgs inputs system profile isLinux isDarwin;
  };

  # non-NixOS only: fixes XDG_DATA_DIRS, locales and man pages
  targets.genericLinux.enable = isLinux && genericLinux;

  fonts.fontconfig.enable = true;

  # the unread-news banner on every switch is pure noise
  news.display = "silent";

  home.sessionVariables = {
    # falls back to vim when no emacs daemon is running
    EDITOR = "emacsclient -a vim";
    VISUAL = "emacsclient -c -a vim";
  } // lib.optionalAttrs isDarwin {
    HOMEBREW_NO_AUTO_UPDATE = 1;
    HOMEBREW_NO_ANALYTICS = 1;
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.grok/bin" # grok's own installer puts its launcher here
  ] ++ lib.optionals isDarwin [ "/opt/homebrew/bin" ];

  home.language = {
    base = "en_US.UTF-8";
    ctype = "en_US.UTF-8";
  };

  # out of store, so editing config.el needs `doom sync` but not a rebuild
  xdg.configFile."doom" = lib.mkIf isFull {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/emacs/doom";
  };

  # written directly so it does not fight a system-level nix install
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
    warn-dirty = false
  '';
}
