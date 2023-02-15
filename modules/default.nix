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
    rtp = pkgs.buildEnv {
      name = "neovim-rtp";
      # paths = config.neovim.build.runtimepath;
      paths = [];
    };

    init-lua = pkgs.writeTextFile {
      name = "init.lua";
      text = ''
        -- Generated by Nix (via github:willruggiano/neovim.nix)
        vim.opt.runtimepath = "${rtp},$VIMRUNTIME"

        -- TODO: This is a super simple approach?
        -- Why do we even need a neovim-nix lua module?
        vim.cmd.source "${config.neovim.build.vimOptions}"
        vim.cmd.source "${config.neovim.build.vimGlobals}"

        -- TODO: This might be a nicer interface?
        -- require("neovim-nix").setup {...}
        -- But for now...
        -- require "neovim-nix.options"
      '';
    };

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
      pkgs,
      ...
    }: {
      options = {
        neovim = {
          final = mkOption {
            type = types.package;
            description = "The final Neovim derivation, with all user configuration baked in";
            internal = true;
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
