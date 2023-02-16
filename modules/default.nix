{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;

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
        + ''
          ${config.neovim.package}/bin/nvim --clean -u ${config.neovim.build.initlua} "$@"
        '';

      checkPhase = ''
        runHook preCheck
        ${pkgs.stdenv.shellDryRun} "$target"
        ${pkgs.shellcheck}/bin/shellcheck "$target"
        runHook postCheck
      '';
    };
  in
    pkgs.buildEnv {
      name = "neovim-env";
      paths = [wrapper];
      meta.mainProgram = "nvim";
      passthru = {
        inherit (config.neovim.build) initlua globals options plugins;
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
      options = {
        neovim = {
          final = mkOption {
            type = types.package;
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
