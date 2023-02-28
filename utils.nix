{
  stdenv,
  vimUtils,
  ...
}:
stdenv.mkDerivation {
  name = "neovim-utils";

  dontFetch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  passthru = {
    mkPlugin = vimUtils.buildVimPluginFrom2Nix;
  };
}
