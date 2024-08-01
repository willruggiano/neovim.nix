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
        lib,
        pkgs,
        ...
      }: {
        neovim = {
          env = {
            BUILT_WITH_NEOVIM_NIX = "fuck yeah it is";
          };
          paths = [pkgs.stylua];

          lazy = {
            settings = {
              performance.rtp = {
                disabled_plugins = [
                  "gzip"
                  "matchit"
                  "netrwPlugin"
                ];
              };
            };
            plugins = {
              example = {
                src = ./example;
                init = ''
                  function()
                    vim.g.loaded_example_init = true
                  end
                '';
                config = ./example.lua;
                lazy = false;
                priority = 1000;
                dependencies = {
                  lfs = let
                    package = pkgs.luajitPackages.luafilesystem;
                  in {
                    inherit package;
                    cpath = "${package}/lib/lua/5.1/?.so";
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

        checks = config.packages.ci;

        packages.default = config.neovim.final;
      };
    };
}
