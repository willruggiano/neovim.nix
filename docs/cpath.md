# Plugins that require dynamic libraries

(from [../example/flake.nix])

```nix
{
  neovim.lazy.plugins = {
    lfs = let
      package = pkgs.luajitPackages.luafilesystem;
    in {
      inherit package;
      cpath = "${package}/lib/lua/5.1/?.so";
    };
  };
}
```
