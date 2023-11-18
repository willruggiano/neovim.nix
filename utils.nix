{
  stdenv,
  luajit,
  vimUtils,
  ...
}:
stdenv.mkDerivation {
  name = "neovim-utils";

  dontFetch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  passthru = let
    lualib = luajit.pkgs.luaLib;
    luajitPackages = luajit.pkgs;
  in {
    mkPlugin = vimUtils.buildVimPluginFrom2Nix;
    toLuarocksPlugin = originalLuaDrv: let
      inherit (luajitPackages) luarocksMoveDataFolder;
      luaDrv = lualib.overrideLuarocks originalLuaDrv (drv: {
        extraConfig = ''
          lua_modules_path = "lua"
        '';
      });
    in
      vimUtils.toVimPlugin (luaDrv.overrideAttrs (oa: {
        nativeBuildInputs = oa.nativeBuildInputs ++ [luarocksMoveDataFolder];
      }));
  };
}
