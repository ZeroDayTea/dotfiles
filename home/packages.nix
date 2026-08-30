# a plain function, not a module, so the flake can reuse it in buildEnv
{ lib, pkgs, inputs, system, profile, isLinux, isDarwin }:

let
  isMinimal = profile == "minimal";
  isFull = profile == "full";

  whenNotMinimal = lib.optionals (!isMinimal);
  whenFull = lib.optionals isFull;

  python = import ./python-packages.nix { inherit pkgs; };

  minimalSet = with pkgs; [
    (if isDarwin then coreutils-prefixed else coreutils)
    curl
    fd
    findutils
    ripgrep
    unzip
    vim
    wget
  ];

  llmSet = with pkgs; [
    claude-code
    codex
    grok-build
  ];

  buildSet = with pkgs; [
    ccache
    clang-tools
    cmake
    gnumake
    ninja
    pkg-config
  ];

  lspSet = with pkgs; [
    bash-language-server
    nil # nix
    pyright
    rust-analyzer
    typescript-language-server
    vscode-langservers-extracted # html, css, json
    yaml-language-server
  ];

  cliSet = with pkgs; [
    fnm # node version manager
    mosh # survives the disconnects ssh does not
    nixfmt
    nodejs
    shellcheck
  ] ++ [ python ];

  headlessSet = llmSet ++ buildSet ++ lspSet ++ cliSet;

  editorSet = with pkgs; [
    (if isDarwin then emacs-macport else emacs)
    nerd-fonts.symbols-only
  ];

  ocamlSet = with pkgs; [
    dune_3
    ocaml
    ocamlPackages.merlin
    ocamlPackages.ocaml-lsp
    ocamlPackages.ocp-indent
    ocamlPackages.utop
    ocamlformat
    opam
  ];

  rustSet = with pkgs; [
    cargo
    clippy
    rustc
    rustfmt
  ];

  miscSet = with pkgs; [
    qemu
  ];

  fullSet = editorSet
    ++ ocamlSet
    ++ rustSet
    ++ miscSet;

  linuxSet = (with pkgs; whenNotMinimal [
    gcc
    ltrace
    strace
    valgrind
  ]) ++ (with pkgs; whenFull [
    docker-compose
    gdb
    wireshark

    inputs.pwndbg.packages.${system}.default

    pkgsCross.aarch64-multiplatform.buildPackages.binutils
    pkgsCross.aarch64-multiplatform.buildPackages.gcc
  ]);

  darwinSet = (with pkgs; whenNotMinimal [
    # GNU userland, so scripts behave the same as on Linux
    diffutils
    gawk
    gnugrep
    gnused
    gnutar
    lldb
  ]);
in
minimalSet
++ whenNotMinimal headlessSet
++ whenFull fullSet
++ lib.optionals isLinux linuxSet
++ lib.optionals isDarwin darwinSet
