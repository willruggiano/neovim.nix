{
  flake-parts-lib,
  lib,
  ...
}:
with lib; let
  inherit (flake-parts-lib) mkPerSystemOption;

  mkNeovimEnv = {
    config,
    pkgs,
    ...
  }: let
    cfg = config.neovim;
    toEnvVar = name: value: ''export ${name}="''${${name}:-${toString value}}"'';
    sourceFile = file: ''
      # shellcheck disable=SC1091
      source ${file}
    '';
    makeLuaSearchPath = paths: concatStringsSep ";" (filter (x: x != null) paths);
  in
    pkgs.writeShellApplication {
      name = "nvim";
      text = concatStringsSep "\n" (
        # NOTE: We don't use writeShellApplication's `runtimeEnv` argument since
        # it does not allow the specified environment variables to be overridden
        # (e.g. by direnv).
        optionals (cfg.env != {}) (mapAttrsToList toEnvVar cfg.env)
        # NOTE: Similar sentiment here. We don't use writeShellApplication's
        # `runtimeInputs` because it would *prepend* `cfg.paths`. What we want,
        # rather, is to *append* them such that they too can be overridden.
        ++ optional (cfg.paths != []) ''
          export PATH="$PATH:${makeBinPath (unique cfg.paths)}"
        ''
        ++ optional (cfg.cpaths != []) ''
          export LUA_CPATH="''${LUA_CPATH:-};${makeLuaSearchPath cfg.cpaths}"
        ''
        ++ optionals (cfg.source != []) (map sourceFile cfg.source)
        ++ [
          ''
            export NVIM_RPLUGIN_MANIFEST="${config.neovim.build.rplugin}/rplugin.vim"
            ${cfg.package}/bin/nvim -u ${cfg.build.initlua} "$@"
          ''
        ]
      );
      derivationArgs.passthru = {
        inherit (config.neovim.build) initlua plugins;
      };
    };
in {
  imports = [
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
          cpaths = mkOption {
            internal = true;
            type = listOf str;
            default = [];
          };
          paths = mkOption {
            type = listOf package;
            default = [];
            description = "Additional binaries to bake into the final Neovim derivation's PATH";
          };
          source = mkOption {
            type = listOf (oneOf [path str]);
            default = [];
            description = "Additional shell scripts to `source` in the generated wrapper script";
          };

          final = mkOption {
            type = package;
            description = "The final Neovim derivation, with all user configuration baked in";
          };
        };
      };
    });
  };

  config = {
    perSystem = {
      config,
      pkgs,
      ...
    }: {
      neovim = {
        final = mkNeovimEnv {inherit config pkgs;};
      };
    };
  };
}
