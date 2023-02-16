{lib}: let
  inherit (builtins) isFunction typeOf;
  inherit (lib) concatStringsSep concatMapStringsSep mapAttrsToList mkOption types;
in rec {
  mkLuaOption = type:
    mkOption {
      type = types.nullOr (types.oneOf [type (types.functionTo type)]);
      default = null;
    };

  toLuaHashMap = v: "{ ${concatStringsSep ", " (mapAttrsToList (name: value: "${name} = ${toLua value}") v)} }";

  toLuaArray = v: "{ ${concatMapStringsSep ", " toLua v} }";

  # TODO: Surely there is a better way?
  toLua = v:
    if v == null
    then "nil"
    else if (typeOf v) == "string"
    then ''"${v}"''
    else if (typeOf v) == "bool"
    then
      if v
      then "true"
      else "false"
    else if (typeOf v) == "set"
    then toLuaHashMap v
    else if (typeOf v) == "list"
    then toLuaArray v
    else if isFunction v
    then v {}
    else toString v;
}
