# Defining plugins

This library uses [lazy.nvim][lazy] under the hood to manage _loading_ plugins,
while nix is used (obviously) to source and build plugins.

## Plugin specification

The plugin specification file should be a nix function:

```nix
{pkgs,...}: {
  <name> = {
    # These are Nix related options:
    src = <attrset>;
    package = <package>;
    # These are lazy.nvim related options:
    config = <boolean|attrset|path>;
    dependencies = <listOf str|package>;
    event = <str|listOf str>;
    ft = <str|listOf str>;
    keys = <str|listOf str>;
  };
}
```

For example:

```nix
{pkgs,...}: let
  # NOTE: Sources generated using niv
  sources = import ./nix/sources.nix {};
in {
  lir = {
    config = {
      devicons = {
        enable = true;
      };
    };
    dependencies = [
      "nvim-web-devicons"
      "plenary"
    ];
    src = sources."lir.nvim";
  };
}
```

This will result in a lazy.nvim plugin spec similar to the following:

```lua
require("lazy").setup({
  {
    name = "lir",
    dir = "/nix/store/path/to/lir.nvim",
    config = true,
    opts = {
      devicons = {
        enable = true,
      },
    },
    dependencies = {
      { name = "nvim-web-devicons" },
      { name = "plenary" },
    },
  },
}, {})
```

[lazy]: https://github.com/folke/lazy.nvim
