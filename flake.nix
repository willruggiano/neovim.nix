{
  description = "Nix library for building custom Neovim derivations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    example = {
      url = "path:./example";
      inputs = {
        flake-parts.follows = "flake-parts";
        neovim-nix.follows = "/";
        nixpkgs.follows = "nixpkgs";
      };
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "";
    };
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports =
        if inputs.git-hooks ? flakeModule
        then [inputs.git-hooks.flakeModule]
        else [];

      flake.flakeModule = {
        imports = [./modules];
      };

      systems = ["aarch64-darwin" "x86_64-linux"];
      perSystem = {
        config,
        inputs',
        lib,
        pkgs,
        system,
        ...
      }:
        {
          checks.ci = pkgs.stdenvNoCC.mkDerivation {
            name = "neovim-nix-ci";
            dontUnpack = true;
            dontPatch = true;
            dontConfigure = true;
            dontBuild = true;
            doCheck = true;
            checkPhase = let
              pkg = config.packages.example;
            in ''
              HOME=$TMP ${lib.getExe pkg} --headless -n -c "PlenaryBustedDirectory ${./example/spec} { init = '${pkg.initlua}' }"
            '';
            installPhase = ''
              touch $out
            '';
          };
          formatter = pkgs.alejandra;
          packages.example = inputs'.example.packages.default;
        }
        // inputs.nixpkgs.lib.optionalAttrs (inputs.git-hooks ? flakeModule) {
          devShells.default = pkgs.mkShell {
            name = "neovim.nix";
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };

          pre-commit = {
            settings = {
              hooks.alejandra.enable = true;
              hooks.stylua.enable = true;
            };
          };
        };
    };
}
