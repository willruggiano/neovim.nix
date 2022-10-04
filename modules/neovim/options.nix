{
  self,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption mkPackageOption types;
in {
  options = {
    perSystem = mkPerSystemOption ({
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }: {
      options = {
        neovim = {
          package = mkPackageOption pkgs "neovim" {};

          options = {
            grepprg = mkOption {
              type = types.str;
              description = "vim.opt.grepprg";
            };

            out = mkOption {
              internal = true;
              type = types.package;
            };
          };
        };
      };
    });
  };

  config = {
    perSystem = {
      config,
      self',
      inputs',
      pkgs,
      ...
    }: {
      neovim.options.out = pkgs.writeTextFile {
        name = "options.lua";
        text = ''
          vim.opt.grepprg = "${config.neovim.options.grepprg}"
        '';
      };
    };
  };
}
