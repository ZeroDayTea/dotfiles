{ description = "zdtdev";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in pkgs.buildEnv {
        name = "zdt-dev-env";
        paths = with pkgs; [
          # emacs
          emacs

          # llms
          claude-code codex

          # build
          cmake gcc gnumake pkg-config clang-tools gdb

          # lsp/language-servers
          nodejs_24 rust-analyzer

          # languages
          ocaml opam dune_3 ocamlPackages.utop ocamlPackages.ocp-indent ocamlPackages.merlin

          ghc stack haskell-language-server haskellPackages.hoogle hlint stylish-haskell cabal-install

          rustc cargo rustfmt clippy

          zig

          ruby_3_4 gem

          python3 python3Packages.pip python3Packages.setuptools python3Packages.isort python3Packages.pytest pipenv pwntools python3Packages.pycryptodome

          solc

          # dev dependencies
          openssl.dev zlib.dev

          # utilities
          git curl wget vim ripgrep findutils fd pandoc shellcheck unzip wireshark
        ];
      };
  };
}
