{
  description = "Example usage of willruggiano/neovim.nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    neovim-nix.url = "github:willruggiano/neovim.nix";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.neovim-nix.flakeModule
      ];

      systems = ["x86_64-linux"];
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        neovim = {
          env = {
            BUILT_WITH_NEOVIM_NIX = true;
          };
          paths = [pkgs.stylua];

          lazy = {
            settings = {
              disabled_plugins = [
                "gzip"
              ];
            };
            plugins = {
              example = {
                src = ./example;
                config = ./example.lua;
                lazy = false;
                priority = 1000;
                dependencies = {
                  lfs = let
                    package = pkgs.luajitPackages.lfs;
                  in {
                    inherit package;
                    init = pkgs.writeTextFile {
                      name = "lfs.lua";
                      text = ''
                        return function()
                          -- TODO: It'd be nice to detect this automatically
                          package.cpath = package.cpath .. ";" .. "${package}/lib/lua/5.1/?.so"
                        end
                      '';
                    };
                  };

                  plenary = {
                    package = pkgs.vimPlugins.plenary-nvim;
                  };
                };
                paths = [pkgs.luajitPackages.luacheck];
              };
            };
          };
        };

        packages.default = config.neovim.final;
      };
    };
}
