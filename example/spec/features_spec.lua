describe("neovim", function()
  it("(env) sets environment variables", function()
    assert.equal("fuck yeah it is", vim.env.BUILT_WITH_NEOVIM_NIX)
  end)

  it("(paths) adds to PATH", function()
    assert.equal(1, vim.fn.executable "stylua")
  end)

  describe("lazy", function()
    it("(settings) disables builtin plugins", function()
      assert.equal(0, vim.fn.exists "loaded_gzip")
      assert.equal(0, vim.fn.exists "loaded_matchit")
      assert.equal(0, vim.fn.exists "loaded_netrwPlugin")
    end)

    describe("plugins", function()
      local _, example = pcall(require, "example")

      it("(<name>) adds plugins", function()
        assert.is_function(example.say_hello)
      end)

      it("(dependencies) adds plugin dependencies", function()
        assert.is_table(require "lfs")
        assert.is_table(require "plenary")
      end)

      it("(config) configures plugins", function()
        assert.is_true(vim.g.loaded_example)
      end)

      it("(paths) add plugin specific paths to PATH", function()
        assert.equal(1, vim.fn.executable "luacheck")
      end)
    end)
  end)
end)
