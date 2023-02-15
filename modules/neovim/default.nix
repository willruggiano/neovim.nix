{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in {
  imports = [
    ./globals.nix
    ./options.nix
  ];

  options = {
    perSystem = mkPerSystemOption ({
      inputs',
      config,
      ...
    }: {
      options = {
        neovim = {
          package = mkOption {
            type = types.package;
            description = "The Neovim derivation to use";
            inherit (inputs'.neovim.packages) default;
          };

          build = {
            runtimepath = mkOption {
              internal = true;
              type = types.listOf types.package;
              default = [];
            };
          };
        };
      };
    });
  };
}
