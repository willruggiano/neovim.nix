{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) concatStringsSep mkOption types;

  mkInitLua = {
    config,
    pkgs,
    rtp,
  }:
    pkgs.writeTextFile {
      name = "init.lua";
      text = ''
        -- Generate by Nix (via github:willruggiano/neovim.nix)
        vim.opt.runtimepath = "${rtp.before},$VIMRUNTIME,${rtp.after}"

        vim.cmd.source "${config.neovim.build.globals}"
        vim.cmd.source "${config.neovim.build.options}"
        vim.cmd.source "${config.neovim.build.plugins}"
      '';
    };
in {
  imports = [
    ./globals.nix
    ./options.nix
  ];

  options = {
    perSystem = mkPerSystemOption ({
      inputs',
      config,
      pkgs,
      ...
    }: {
      options = {
        neovim = {
          package = mkOption {
            type = types.package;
            description = "The Neovim derivation to use";
            inherit (inputs'.neovim.packages) default;
          };

          build = {
            initlua = mkOption {
              internal = true;
              type = types.package;
            };

            runtimepath = mkOption {
              internal = true;
              type = types.listOf types.package;
              default = [];
            };
          };
        };
      };

      config = {
        neovim.build.initlua = mkInitLua {
          inherit config pkgs;
          rtp = let
            rtp = config.neovim.build.runtimepath;
          in {
            before = concatStringsSep "," (map (p: "${p}") rtp);
            after = concatStringsSep "," (map (p: "${p}/after") rtp);
          };
        };
      };
    });
  };
}
