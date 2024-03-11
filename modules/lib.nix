{lib}: let
  inherit (lib) mkOption types;
in {
  mkLuaOption = type:
    mkOption {
      type = types.nullOr (types.oneOf [type (types.functionTo type)]);
      default = null;
    };

  # TODO: Maybe?
  # usage: neovim-lib.importPluginFromSpec ./plugins.nix {inherit ...};
  importPluginFromSpec = path: attrs: let
    # FIXME: Bad. Inputs can be named anything.
    # Any these are the inputs of the CONSUMING flake. Not even this one!
    inherit (attrs.inputs'.neovim-nix.packages) utils;
  in {
  };
}
