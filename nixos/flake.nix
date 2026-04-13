{
  description = "zdtdev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    pwndbg.url = "github:pwndbg/pwndbg";
  };

  outputs = { self, nixpkgs, pwndbg }: {
    packages.x86_64-linux.default =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };

        pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
          pip
          setuptools
          isort
          pytest
          pwntools
          pycryptodome
        ]);

      in pkgs.buildEnv {
        name = "zdt-dev-env";
        paths = with pkgs; [
          # emacs
          emacs

          # llms
          claude-code

          # build
          cmake gcc gnumake pkg-config clang-tools gdb qemu

          # lsp/language-servers
          rust-analyzer

          # languages
          ocaml opam dune_3 ocamlPackages.utop ocamlPackages.ocp-indent ocamlPackages.merlin

          ghc stack haskell-language-server haskellPackages.hoogle hlint stylish-haskell cabal-install

          rustc cargo rustfmt clippy

          zig

          ruby_3_4 gem

          pythonWithPackages pipenv

          solc

          fnm

          # dev dependencies
          openssl.dev zlib.dev

          # utilities
          git curl wget vim ripgrep findutils fd pandoc shellcheck unzip wireshark docker docker-compose

          pwndbg.packages.x86_64-linux.default

          # arm64
          pkgsCross.aarch64-multiplatform.buildPackages.gcc
          pkgsCross.aarch64-multiplatform.buildPackages.binutils
        ];
      };
  };
}
