{
  lib,
  flake-parts-lib,
  neovim-lib,
  ...
}:
with lib; let
  inherit (builtins) typeOf;
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (neovim-lib) toLua;

  pluginSpec = with types; {
    options = {
      src = mkOption {
        type = nullOr (oneOf [attrs path]);
        default = null;
      };
      package = mkOption {
        type = nullOr package;
        default = null;
      };
      name = mkOption {
        type = nullOr str;
        default = null;
      };
      lazy = mkOption {
        type = nullOr bool;
        default = null;
      };
      dependencies = mkOption {
        type = attrsOf (submodule pluginSpec);
        default = {};
      };
      init = mkOption {
        type = nullOr (oneOf [package path]);
        default = null;
      };
      config = mkOption {
        type = nullOr (oneOf [attrs bool package path]);
        default = null;
      };
      opts = mkOption {
        type = attrs;
        default = {};
      };
      event = mkOption {
        type = nullOr (oneOf [str (listOf str)]);
        default = null;
      };
      ft = mkOption {
        type = nullOr (oneOf [str (listOf str)]);
        default = null;
      };
      keys = mkOption {
        type = nullOr (oneOf [str (listOf str)]);
        default = null;
      };
      priority = mkOption {
        type = nullOr int;
        default = null;
      };
      paths = mkOption {
        type = listOf package;
        default = [];
      };
    };
  };
in {
  options = {
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: let
      cfg = config.neovim.lazy;
    in {
      options = with types; {
        neovim = {
          lazy = {
            package = mkOption {
              type = package;
              default = pkgs.vimPlugins.lazy-nvim;
            };
            settings = mkOption {
              type = submodule {
                freeformType = attrsOf anything;
                options = {
                  dev = {
                    path = mkOption {
                      type = nullOr (oneOf [path str]);
                      default = null;
                    };
                  };
                  install = {
                    missing = mkOption {
                      type = bool;
                      default = false;
                    };
                  };
                };
              };
            };
            plugins = mkOption {
              type = attrsOf (submodule pluginSpec);
              default = {};
            };
          };

          build = {
            lazy = {
              spec = mkOption {
                type = str;
                internal = true;
              };
              opts = mkOption {
                type = str;
                internal = true;
              };
            };

            plugins = mkOption {
              type = package;
              internal = true;
            };
          };
        };
      };

      config = mkIf (cfg.plugins != []) {
        neovim.build = let
          inherit (config.neovim) build;
          inherit (pkgs.vimUtils) buildVimPluginFrom2Nix;

          mkPlugin = name: attrs:
            if attrs.package != null
            then attrs.package
            else
              buildVimPluginFrom2Nix {
                inherit name;
                inherit (attrs) src;
                leaveDotGit = true; # So some lazy features (commands) work properly
              };
        in {
          lazy = let
            toPlugin' = name: attrs: let
              package = mkPlugin name attrs;
            in
              {
                inherit name;
                dir = "${package}";
              }
              // optionalAttrs (attrs.lazy != null) {inherit (attrs) lazy;}
              // optionalAttrs (attrs.dependencies != {}) {
                dependencies = let
                  deps = mapAttrs toPlugin' attrs.dependencies;
                in
                  attrValues deps;
              }
              // optionalAttrs (isDerivation attrs.init || typeOf attrs.init == "path") {
                init = _: ''
                  dofile "${attrs.init}"
                '';
              }
              # // optionalAttrs (typeOf attrs.init == "path") {
              # TODO: This is better, but... stack overflow
              # init = pkgs.writeTextFile {
              #   name = "${name}-init.lua";
              #   text = ''
              #     dofile "${attrs.init}"
              #   '';
              # };
              # }
              // optionalAttrs (typeOf attrs.config == "bool") {
                inherit (attrs) config;
              }
              // optionalAttrs (isDerivation attrs.config || typeOf attrs.config == "path") {
                # TODO: This is better, but... stack overflow
                # config = pkgs.writeTextFile {
                #   name = "${name}-config.lua";
                #   text = ''
                #     dofile "${attrs.config}"
                #   '';
                # };
                config = _: ''
                  dofile "${attrs.config}"
                '';
              }
              // optionalAttrs (builtins.isAttrs attrs.config) {
                config = true;
                opts = attrs.config;
              }
              // optionalAttrs (attrs.event != null) {inherit (attrs) event;}
              // optionalAttrs (attrs.ft != null) {inherit (attrs) ft;}
              // optionalAttrs (attrs.keys != null) {inherit (attrs) keys;}
              // optionalAttrs (attrs.priority != null) {inherit (attrs) priority;};

            spec = toLua (mapAttrsToList toPlugin' cfg.plugins);
            opts = toLua ({performance.rtp.reset = false;} // cfg.settings);
          in {
            inherit spec opts;
          };

          plugins =
            pkgs.runCommand "plugins.lua" {
              nativeBuildInputs = with pkgs; [stylua];
              passAsFile = ["text"];
              preferLocalBuild = true;
              allowSubstitutes = false;
              text = ''
                -- Generated by Nix (via github:willruggiano/neovim.nix)
                vim.opt.rtp:prepend "${cfg.package}"
                require("lazy").setup(${build.lazy.spec}, ${build.lazy.opts})
              '';
            } ''
              target=$out
              mkdir -p "$(dirname "$target")"
              if [ -e "$textPath" ]; then
                mv "$textPath" "$target"
              else
                echo -n "$text" > "$target"
              fi

              stylua --config-path ${../../stylua.toml} $target
            '';
        };

        neovim.paths = let
          toPaths = name: attrs: let
            paths = attrs.paths or [];
          in
            paths ++ (mapAttrsToList toPaths (attrs.dependencies or {}));
          paths = mapAttrsToList toPaths cfg.plugins;
        in
          mkAfter (flatten paths);
      };
    });
  };
}
