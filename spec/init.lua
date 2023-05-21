describe("neovim", function()
  it("(env) sets environment variables", function()
    assert.equal("true", vim.env.BUILT_WITH_NEOVIM_NIX)
  end)

  it("(paths) adds to PATH", function()
    assert.is_executable "stylua"
  end)

  describe("lazy", function()
    it("(settings) disables builtin plugins", function()
      assert.is_true(vim.fn.exists "loaded_gzip" == 0)
    end)

    describe("plugins", function()
      local _, example = pcall(require, "example")

      it("(<name>) adds plugins", function()
        assert.is_table(package.loaded.example)
        assert.is_function(example.say_hello)
      end)

      it("(dependencies) adds plugin dependencies", function()
        assert.is_table(package.loaded.lfs)
        assert.is_table(package.loaded.plenary)
      end)

      it("(config) configures plugins", function()
        assert.is_true(vim.g.loaded_example)
      end)

      it("(paths) add plugin specific paths to PATH", function()
        assert.is_executable "luacheck"
      end)
    end)
  end)
end)
