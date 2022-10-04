{
  description = "Nix library for building custom Neovim derivations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim.url = "github:neovim/neovim?dir=contrib";
    pre-commit-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-nix.flakeModule
      ];

      flake = {
        lib = import ./lib {inherit (inputs.nixpkgs) lib;};
        flakeModule = {
          imports = [./modules];
        };
      };

      systems = ["x86_64-linux"];
      perSystem = {
        config,
        pkgs,
        inputs',
        ...
      }: {
        devShells.default = pkgs.mkShell {
          name = "neovim.nix";
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        formatter = pkgs.alejandra;

        pre-commit = {
          settings = {
            hooks.alejandra.enable = true;
            hooks.stylua.enable = true;
          };
        };
      };
    };
}
