{
  description = "Nix library for building custom Neovim derivations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lazy-nvim.url = "github:folke/lazy.nvim";
    lazy-nvim.flake = false;
    neovim.url = "github:neovim/neovim?dir=contrib";
    pre-commit-nix.url = "github:cachix/pre-commit-hooks.nix";

    # FIXME: This would be nice, and also a test of sorts
    # example = {
    #   url = "path:./example";
    #   inputs = {
    #     # FIXME: override for a non-existent input 'nixpkgs'
    #     # nixpkgs.follows = "nixpkgs";
    #     flake-parts.follows = "flake-parts";
    #     # FIXME: override for a non-existent input 'neovim-nix'
    #     # neovim-nix.follows = "self";
    #   };
    # };
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
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              neovim = inputs'.neovim.packages.default;
              neovim-unwrapped = inputs'.neovim.packages.default;
            })
          ];
        };
      in {
        _module.args.pkgs = pkgs;

        devShells.default = pkgs.mkShell {
          name = "neovim.nix";
          shellHook = ''
            ${config.pre-commit.installationScript}
          '';
        };

        formatter = pkgs.alejandra;

        packages = {
          # example = inputs'.example.packages.default;
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
