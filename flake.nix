{
  description = "Nix library for building custom Neovim derivations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "";
    };
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports =
        if inputs.git-hooks ? flakeModule
        then [inputs.git-hooks.flakeModule]
        else [];

      flake.flakeModule = {
        imports = [./modules];
      };

      systems = ["aarch64-darwin" "x86_64-linux"];
      perSystem = {
        config,
        inputs',
        pkgs,
        system,
        ...
      }:
        {
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

          formatter = pkgs.alejandra;
        }
        // inputs.nixpkgs.lib.optionalAttrs (inputs.git-hooks ? flakeModule) {
          devShells.default = pkgs.mkShell {
            name = "neovim.nix";
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
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
