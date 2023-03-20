{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) makeBinPath mkOption optionalString types;

  mkNeovimEnv = {
    config,
    pkgs,
    ...
  }: let
    # TODO: Use wrapProgram?
    wrapper = pkgs.writeTextFile rec {
      name = "nvim";
      executable = true;
      destination = "/bin/${name}";
      text =
        ''
          #!${pkgs.runtimeShell}
          set -o errexit
          set -o nounset
          set -o pipefail
        ''
        + optionalString (config.neovim.paths != []) ''
          export PATH="$PATH:${makeBinPath config.neovim.paths}"
        ''
        + ''
          export NVIM_RPLUGIN_MANIFEST="${config.neovim.build.rplugin}/rplugin.vim"
          ${config.neovim.package}/bin/nvim -u ${config.neovim.build.initlua} "$@"
        '';

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
