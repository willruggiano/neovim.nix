{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) concatStringsSep mkOption optional types;

  mkInitLua = {
    config,
    pkgs,
    cpath,
    rtp,
  }:
    pkgs.writeTextFile {
      name = "init.lua";
      text = ''
        -- Generate by Nix (via github:willruggiano/neovim.nix)
        vim.opt.runtimepath = "${rtp.before},$VIMRUNTIME,${rtp.after}"
        package.cpath = "${cpath};;"

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
      options = with types; {
        neovim = {
          package = mkOption {
            type = package;
            description = "The Neovim derivation to use";
            inherit (inputs'.neovim.packages) default;
          };

          src = mkOption {
            type = nullOr path;
            description = "The root directory of your dotfiles, to be added to 'runtimepath'";
            default = null;
          };

          build = {
            initlua = mkOption {
              internal = true;
              type = package;
            };

            cpath = mkOption {
              internal = true;
              type = listOf (oneOf [package path]);
            };

            runtimepath = mkOption {
              internal = true;
              type = listOf (oneOf [package path]);
              default = [];
            };
          };
        };
      };

      config = {
        neovim.build.initlua = mkInitLua {
          inherit config pkgs;

          cpath = let
            plugins = config.neovim.build.plugins';
          in
            concatStringsSep ";" (map (p: "${p}/lib/?.so;${p}/lib/lua/5.1/?.so") plugins);

          rtp = let
            inherit (config.neovim) src;
            rtp = config.neovim.build.runtimepath ++ (optional (src != null) src);
          in {
            before = concatStringsSep "," (map (p: "${p}") rtp);
            after = concatStringsSep "," (map (p: "${p}/after") rtp);
          };
        };
      };
    });
  };
}
