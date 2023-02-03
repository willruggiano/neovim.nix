{
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in {
  options = {
    vim.opt = {
      # TODO: We will probably want to generate these at some point.
      grepprg = mkOption {
        type = types.str;
        description = "vim.opt.grepprg";
      };
    };

    perSystem = mkPerSystemOption (_: {
      options = {
        neovim.build = {
          vimOptions = mkOption {
            internal = true;
            type = types.package;
          };
        };
      };
    });
  };

  config = {
    perSystem = {pkgs, ...}: {
      neovim.build.vimOptions = let
        mod = pkgs.writeText "options.lua" ''
          vim.opt.grepprg = "${config.vim.opt.grepprg}"
        '';
      in
        pkgs.stdenvNoCC.mkDerivation {
          name = "neovim-options";

          dontUnpack = true;
          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lua/neovim-nix
            ln -s ${mod} $out/lua/neovim-nix/options.lua
            runHook postInstall
          '';
        };
    };
  };
}
