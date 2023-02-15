{
  lib,
  flake-parts-lib,
  ...
}:
with lib; let
  inherit (flake-parts-lib) mkPerSystemOption;
in {
  imports = [
    ./lir.nix
  ];

  options = {
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: {
      options = {
        neovim = {
          build = {
            packpath = mkOption {
              internal = true;
              type = types.package;
            };

            plugins = mkOption {
              internal = true;
              type = types.listOf types.package;
              default = [];
            };
          };
        };
      };

      config = let
        inherit (pkgs.vimUtils) packDir;
        plugins = listToAttrs (map (p: nameValuePair p.name p) config.neovim.build.plugins);
        plugins' = mapAttrs (_: p: {start = [p];}) plugins;
      in {
        neovim.build = {
          packpath = pkgs.buildEnv {
            name = "neovim-packages";
            paths = [(packDir plugins')];
          };
        };
      };
    });
  };
}
