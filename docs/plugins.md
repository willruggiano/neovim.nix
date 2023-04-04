# Defining plugins

This library uses [lazy.nvim][lazy] under the hood to manage _loading_ plugins,
while nix is used (obviously) to source and build plugins.

## Plugin specification

The plugin specification file should be a nix function:

```nix
{pkgs,...}: {
  <name> = <pluginSpec>;
}
```

See [the pluginSpec](../modules/plugins/default.nix) for all options and their acceptable option types.

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
    dependencies = {
      nvim-web-devicons = {
        src = sources.nvim-web-devicons;
        config = ./devicons.lua;
      };
      plenary = {
        src = sources."plenary.nvim";
      };
    };
    src = sources."lir.nvim";
  };
}
```

IMPORTANT: the name of each plugin (including dependencies) should be
the name of the Lua module. This has to do with how lazy.nvim works.

NOTE: when running Neovim, all of the normal lazy.nvim user commands
will be available. Many of them will not work/won't be useful. This
includes commands related to installing or updating plugins,
`:Lazy install` and `:Lazy update` for example. Additionally, many
lazy commands require plugin directories to be git repositories,
`:Lazy check` for example.
These commands will not work either as the .git directories are
removed by nix during the packaging stage.

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
      {
        name = "nvim-web-devicons",
        dir = "/nix/store/path/to/nvim-web-devicons",
        config = dofile "/nix/store/path/to/devicons.lua",
      },
      {
        name = "plenary",
        dir = "/nix/store/path/to/plenary.nvim",
      },
    },
  },
}, {})
```

NOTE: when passing paths and/or derivations as "config" and "init" options
for a plugin, the resulting nix store paths are `dofile`d into the lazy.nvim
spec. This means that whatever those files return should be a valid type
for lazy.nvim's "config" and "init" options! For example, the following might
be the contents of "devicons.lua" in the above example:

```lua
return function()
  require("nvim-web-devicons").setup {
    override = {
      lir_folder_icon = {
        icon = ...,
        color = ...,
        name = "LirFolderNode",
      },
    },
  }
end
```

## Plugins that require dynamic libraries (or luarocks)

See [cpath.md](./cpath.md)

[lazy]: https://github.com/folke/lazy.nvim
