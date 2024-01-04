{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) concatStringsSep makeBinPath mapAttrsToList mkOption optional types unique;

  mkNeovimEnv = {
    config,
    pkgs,
    ...
  }: let
    cfg = config.neovim;

    # TODO: Use wrapProgram?
    wrapper = pkgs.writeTextFile rec {
      name = "nvim";
      executable = true;
      destination = "/bin/${name}";
      text = concatStringsSep "\n" ([
          ''
            #!${pkgs.runtimeShell}
            set -o errexit
            set -o nounset
            set -o pipefail
          ''
        ]
        ++ optional (cfg.paths != []) ''
          export PATH="$PATH:${makeBinPath (unique cfg.paths)}"
        ''
        ++ [
          ''
            ${concatStringsSep "\n" (mapAttrsToList (name: value: ''export ${name}="''${${name}:-${toString value}}"'') cfg.env)}
          ''
        ]
        ++ [
          ''
            export NVIM_RPLUGIN_MANIFEST="${config.neovim.build.rplugin}/rplugin.vim"
            ${cfg.package}/bin/nvim -u ${cfg.build.initlua} "$@"
          ''
        ]);

      checkPhase = ''
        runHook preCheck
        ${pkgs.stdenv.shellDryRun} "$target"
        ${pkgs.shellcheck}/bin/shellcheck "$target"
        runHook postCheck
      '';

      meta.mainProgram = name;
    };
  in
    pkgs.buildEnv {
      name = "neovim-env";
      paths = [wrapper];
      meta.mainProgram = "nvim";
      passthru = {
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
