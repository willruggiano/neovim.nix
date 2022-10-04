# Plugin specification

`makeNeovimEnv` accepts an attribute set defining plugins to be installed inside the custom Neovim environment;

```nix
makeNeovimEnv {
  ...
  plugins = {
    ...
  };
}
```

The `plugins` attribute has the following specification;

```nix
plugins = {
  <name> = {
    package = <derivation>;     # REQUIRED
    config = <str or path>;     # OPTIONAL
    after = <listOf names>;     # OPTIONAL
    before = <listOf names>;    # OPTIONAL
    requires = <listOf names>;  # OPTIONAL
    wants = <listOf names>;     # OPTIONAL
    optional = <bool>;          # OPTIONAL; default false
  };
};
```

- `name`: the name of the plugin, which need not be the same as the `pname` of the derivation.
    - Plugins are installed to Neovim's pack dir, e.g. `neovim-root/site/pack/nix/start/<name>`
    - Can be used to reference this plugin in other plugin spec's `after`
