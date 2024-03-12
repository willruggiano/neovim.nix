{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) makeBinPath mkOption types unique;

  mkNeovimEnv = {
    config,
    pkgs,
    ...
  }: let
    cfg = config.neovim;
  in
    pkgs.writeShellApplication {
      name = "nvim";
      runtimeEnv =
        (cfg.env or {})
        // {
          NVIM_RPLUGIN_MANIFEST = "${config.neovim.build.rplugin}/rplugin.vim";
        };
      text =
        lib.optionalString (cfg.paths != [])
        ''
          export PATH="$PATH:${makeBinPath (unique cfg.paths)}"
        ''
        + ''
          ${cfg.package}/bin/nvim -u ${cfg.build.initlua} "$@"
        '';
      derivationArgs.passthru = {
        inherit (config.neovim.build) initlua plugins;
      };
    };
in {
  imports = [
    {
      _module.args.neovim-lib = import ./lib.nix {inherit lib;};
    }
    ./neovim
    ./plugins
  ];

  options = {
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: {
      options = with types; {
        neovim = {
          env = mkOption {
            type = attrs;
            default = {};
            description = "Environment variables to bake into the final Neovim derivation's runtime";
          };
          paths = mkOption {
            type = listOf package;
            default = [];
            description = "Additional binaries to bake into the final Neovim derivation's PATH";
          };

          final = mkOption {
            type = package;
            description = "The final Neovim derivation, with all user configuration baked in";
          };
        };
      };

      config = {
        neovim = {
          final = mkNeovimEnv {inherit config pkgs;};
        };
      };
    });
  };
}
