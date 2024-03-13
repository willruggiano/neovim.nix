{
  description = "Nix library for building custom Neovim derivations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lazy-nvim.url = "github:folke/lazy.nvim";
    lazy-nvim.flake = false;
    pre-commit-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    flake-parts,
    self,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit self inputs;} {
      imports = [
        inputs.pre-commit-nix.flakeModule
      ];

      flake = {
        flakeModule = {
          imports = [./modules];
        };
      };

      systems = ["aarch64-darwin" "x86_64-linux"];
      perSystem = {
        config,
        inputs',
        pkgs,
        system,
        ...
      }: {
        apps = {
          check.program = pkgs.writeShellApplication {
            name = "check";
            text = ''
              nix run ./example#test
            '';
          };
          check-local.program = pkgs.writeShellApplication {
            name = "check-local";
            text = ''
              nix run --override-input neovim-nix path:./. ./example#test
            '';
          };
        };

        devShells.default = pkgs.mkShell {
          name = "neovim.nix";
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        formatter = pkgs.alejandra;

        packages = {
          utils = pkgs.callPackage ./utils.nix {};
        };

        pre-commit = {
          settings = {
            hooks.alejandra.enable = true;
            hooks.stylua.enable = true;
          };
        };
      };
    };
}
