{
  description = "zdt's dotfiles: home-manager configurations for Linux and macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pwndbg.url = "github:pwndbg/pwndbg";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      username = "zdt";

      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      # x86_64-darwin is deprecated in nixpkgs-unstable
      darwinSystems = [ "aarch64-darwin" ];
      allSystems = linuxSystems ++ darwinSystems;

      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      mkHome =
        { system
        , profile
        , genericLinux ? nixpkgs.lib.hasSuffix "linux" system
        , user ? username
        , extraModules ? [ ]
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs profile genericLinux;
            username = user;
          };
          modules = extraModules ++ [ ./home ];
        };
    in
    {
      homeConfigurations = {
        # Linux
        "${username}@x86_64-linux-full" = mkHome { system = "x86_64-linux"; profile = "full"; };
        "${username}@x86_64-linux-headless" = mkHome { system = "x86_64-linux"; profile = "headless"; };
        "${username}@x86_64-linux-minimal" = mkHome { system = "x86_64-linux"; profile = "minimal"; };

        "${username}@aarch64-linux-full" = mkHome { system = "aarch64-linux"; profile = "full"; };
        "${username}@aarch64-linux-headless" = mkHome { system = "aarch64-linux"; profile = "headless"; };
        "${username}@aarch64-linux-minimal" = mkHome { system = "aarch64-linux"; profile = "minimal"; };

        # macOS
        "${username}@aarch64-darwin-full" = mkHome { system = "aarch64-darwin"; profile = "full"; };
        "${username}@aarch64-darwin-headless" = mkHome { system = "aarch64-darwin"; profile = "headless"; };
        "${username}@aarch64-darwin-minimal" = mkHome { system = "aarch64-darwin"; profile = "minimal"; };
      };

      # smoke-test a profile with `nix build .#full`, without activating it
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          mkEnv = profile: pkgs.buildEnv {
            name = "zdt-dev-env-${profile}";
            paths = import ./home/packages.nix {
              inherit (pkgs) lib;
              inherit pkgs inputs system profile;
              isLinux = pkgs.stdenv.hostPlatform.isLinux;
              isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
            };
          };
        in
        {
          default = mkEnv "full";
          full = mkEnv "full";
          headless = mkEnv "headless";
          minimal = mkEnv "minimal";

          # switch.sh bootstraps from here when the CLI is not on PATH
          home-manager = home-manager.packages.${system}.default;
        });

      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            name = "dotfiles";
            packages = [
              home-manager.packages.${system}.default
              pkgs.git
              pkgs.nixfmt
            ];
          };
        });

      # ghc/HLS live per project, not in the global profile
      templates.haskell = {
        path = ./templates/haskell;
        description = "Haskell devShell with ghc, cabal and HLS";
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
