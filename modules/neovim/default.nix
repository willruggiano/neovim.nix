{
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in {
  imports = [
    ./options.nix
  ];

  options = {
    perSystem = mkPerSystemOption ({inputs', ...}: {
      options = {
        neovim = {
          package = mkOption {
            type = types.package;
            description = "The Neovim derivation to use";
            inherit (inputs'.neovim.packages) default;
          };
        };

        vim.opt = {
          runtimepath = mkOption {
            internal = true;
            type = types.listOf types.package;
          };
        };
      };
    });
  };

  config = {
    perSystem = {config, ...}: {
      vim.opt.runtimepath = [
        config.neovim.build.vimOptions
      ];
    };
  };
}
