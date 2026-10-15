local function pick_refactor()
  require("refactoring").select_refactor()
end

return {
  {
    "ThePrimeagen/refactoring.nvim",
    -- Newer revisions require Neovim 0.12; this setup intentionally pins 0.11.5.
    commit = "2423b02c400427b9f8d1e28ae3be7da9b291224e",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "lewis6991/async.nvim",
        -- Matches the async API used by the Neovim 0.11-compatible refactoring pin.
        commit = "7a1d7d49933fbe902b84b55f352a3b10fd587331",
      },
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>r", "", desc = "+refactor", mode = { "n", "x" } },
      { "<leader>rs", pick_refactor, desc = "Refactor", mode = { "n", "x" } },
      {
        "<leader>ri",
        function()
          return require("refactoring").inline_var()
        end,
        desc = "Inline Variable",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rP",
        function()
          require("refactoring.debug").print_loc()
        end,
        desc = "Debug Print",
      },
      {
        "<leader>rp",
        function()
          return require("refactoring.debug").print_var()
        end,
        desc = "Debug Print Variable",
        mode = { "n", "x" },
      },
      {
        "<leader>rc",
        function()
          require("refactoring.debug").cleanup()
        end,
        desc = "Debug Cleanup",
      },
      {
        "<leader>rf",
        function()
          return require("refactoring").extract_func()
        end,
        desc = "Extract Function",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rF",
        function()
          return require("refactoring").extract_func_to_file()
        end,
        desc = "Extract Function To File",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rx",
        function()
          return require("refactoring").extract_var()
        end,
        desc = "Extract Variable",
        mode = { "n", "x" },
        expr = true,
      },
    },
    opts = { show_success_message = true },
    config = function(_, opts)
      -- This pinned revision moved setup into its config module.
      require("refactoring.config").setup(opts)
    end,
  },
}
