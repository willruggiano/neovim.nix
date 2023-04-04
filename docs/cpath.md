# Plugins that require dynamic libraries

Both "init" and "config" accept derivations. Use something like `writeTextFile`
to create a derivation that will add the dynamic library to Neovim's cpath.

```nix
{
  lfs = let
    package = luajitPackages.luafilesystem;
  in {
    inherit package;
    init = pkgs.writeTextFile {
      name = "lfs.lua";
      text = ''
        return function()
          package.cpath = package.cpath .. ";" .. "${package}/lib/lua/5.1/?.so"
        end
      '';
    };
  };
}
```

TODO: it would be nice to generalize this somehow. Maybe:

```nix
{
  # mkPluginWithDynamicLibrary would introspect the luarocks derivation
  # and generate the right `writeTextFile` derivation for `init`
  lfs = neovim-lib.mkPluginWithDynamicLibrary {
    package = luajitPackages.luafilesystem;
  };
}
```
