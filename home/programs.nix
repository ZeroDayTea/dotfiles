{ config, lib, pkgs, isDarwin, isLinux, isFull, isMinimal, ... }:

{
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "ZeroDayTea";
      user.email = "patrick.dobranowski@gmail.com";

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      advice.detachedHead = false;

      # performance
      core.commitGraph = true;
      core.preloadIndex = true;
      core.untrackedCache = true;
      fetch.writeCommitGraph = true;
      gc.writeCommitGraph = true;
      diff.algorithm = "histogram";
    };
    ignores = [
      ".direnv/"
      ".DS_Store"
      "result"
      "result-*"
    ];
  };

  # also registers gh as the git credential helper
  programs.gh.enable = true;

  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 100000;
    historyFileSize = 200000;

    shellAliases = {
      emacs = ''emacsclient -c -a ""'';
      ec = ''emacsclient -c -a ""'';
      ll = "ls -alF";
      la = "ls -A";
    };

    initExtra = ''
      # makes less handle archives and binaries, as the distro .bashrc did
      [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

      # nix ships no distro bash-completion on generic Linux
      if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
          . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
          . /etc/bash_completion
        fi
      fi

      # for ad-hoc node versions; the nix nodejs stays the default
      if command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --shell bash)"
      fi

      [ -r "$HOME/.grok/completions/bash/grok.bash" ] && . "$HOME/.grok/completions/bash/grok.bash"
    '';
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      directory.truncation_length = 4;
      git_status.disabled = false;
      nix_shell.format = "via [$symbol$name]($style) ";
    };
  };

  # per-project toolchains, so the global profile can stay smaller
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  programs.tmux = lib.mkIf (!isMinimal) {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 10;
    historyLimit = 100000;
    keyMode = "emacs";
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = ''
      set -as terminal-features ",xterm-256color:RGB,xterm-ghostty:RGB"
      set -g focus-events on
      set -g renumber-windows on
      set -g pane-base-index 1
      set -g set-titles on
      set -g set-titles-string '#{host_short} · #S'

      # open new windows and panes in the current directory
      bind c new-window -c "#{pane_current_path}"
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };

  programs.bat.enable = !isMinimal;
  programs.jq.enable = !isMinimal;
  programs.htop.enable = true;

  # keeps the store from creeping back up between manual cleanups
  nix.gc = lib.mkIf isLinux {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
    persistent = true;
  };

  services.home-manager.autoExpire = lib.mkIf isLinux {
    enable = true;
    frequency = "monthly";
    timestamp = "-30 days";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      Compression = true;
      ServerAliveInterval = 60;
      # reuse one connection per host: much faster repeated ssh/scp/git
      ControlMaster = "auto";
      ControlPath = "~/.ssh/master-%r@%n:%p";
      ControlPersist = "10m";
    };
  };
}
