{
  self,
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
          ${config.neovim.package}/bin/nvim --clean -u ${config.neovim.out.initLua} "$@"
        '';

      checkPhase = ''
        runHook preCheck
        ${pkgs.stdenv.shellDryRun} "$target"
        ${pkgs.shellcheck}/bin/shellcheck "$target"
        runHook postCheck
      '';

      meta.mainprogram = name;
    };
  in
    pkgs.buildEnv {
      name = "neovim-env";
      paths = [wrapper];
    };
in {
  imports = [
    ./neovim
    ./plugins
  ];

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
          env = mkOption {
            type = types.package;
            description = "The final Neovim derivation, with all user configuration baked in";
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
      neovim.env = mkNeovimEnv {inherit config pkgs;};
    };
  };
}
