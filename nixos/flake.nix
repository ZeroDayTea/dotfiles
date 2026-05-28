{
  description = "zdtdev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    pwndbg.url = "github:pwndbg/pwndbg";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, pwndbg, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        inherit (pkgs) lib;
        isLinux = pkgs.stdenv.isLinux;
        isDarwin = pkgs.stdenv.isDarwin;

        pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
          pip
          setuptools
          isort
          pytest
          pwntools
          pycryptodome
        ]);

      in {
        packages.default = pkgs.buildEnv {
          name = "zdt-dev-env";
          paths = with pkgs; [
            # emacs
            (if isDarwin then emacs-macport else emacs)

            # llms
            claude-code

            # build
            cmake gnumake pkg-config clang-tools qemu

            # editor support
            nodejs
            (if isDarwin then coreutils-prefixed else coreutils)
            nerd-fonts.symbols-only
            nixfmt

            # lsp / language servers
            rust-analyzer
            typescript-language-server
            bash-language-server
            yaml-language-server
            nil
            pyright

            # languages
            ocaml opam dune_3 ocamlPackages.utop ocamlPackages.ocp-indent ocamlPackages.merlin

            ghc stack haskell-language-server haskellPackages.hoogle hlint stylish-haskell cabal-install

            rustc cargo rustfmt clippy

            zig

            ruby_3_4

            pythonWithPackages pipenv

            solc

            fnm

            # dev dependencies
            openssl.dev zlib.dev

            # utilities
            git curl wget vim ripgrep findutils fd pandoc shellcheck unzip mermaid-cli gh
          ] ++ lib.optionals isLinux [
            gcc gdb wireshark docker docker-compose

            pwndbg.packages.${system}.default

            # arm64 cross
            pkgsCross.aarch64-multiplatform.buildPackages.gcc
            pkgsCross.aarch64-multiplatform.buildPackages.binutils
          ] ++ lib.optionals isDarwin [
            lldb
          ];
        };
      });
}
