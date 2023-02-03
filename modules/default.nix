{
  config,
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
    # rtp = pkgs.buildEnv {
    #   name = "neovim-rtp";
    #   paths = config.vim.opt.runtimepath;
    # };
    init-lua = pkgs.writeTextFile {
      name = "init.lua";
      text = ''
        -- Generate by Nix (via github:willruggiano/neovim.nix)
        local rtp = vim.opt.runtimepath


        -- TODO: This might be a nicer interface?
        -- require("neovim-nix").setup {...}
        -- But for now...
        require "neovim-nix.options"
      '';
    };

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
          ${config.neovim.package}/bin/nvim --clean -u ${init-lua} "$@"
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
          final = mkOption {
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
      neovim = {
        final = mkNeovimEnv {inherit config pkgs;};
      };
    };
  };
}
