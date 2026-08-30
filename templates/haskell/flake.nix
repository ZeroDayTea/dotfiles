{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ghc = pkgs.haskellPackages.ghcWithPackages (hs: with hs; [
            QuickCheck
            aeson
            containers
            mtl
            text
            vector
          ]);
        in {
          default = pkgs.mkShell {
            packages = [ ghc ] ++ (with pkgs; [
              cabal-install
              haskell-language-server
              hlint
              stylish-haskell
            ]);
          };
        });
    };
}
