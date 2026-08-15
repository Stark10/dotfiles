local function pick_refactor()
  local refactoring = require("refactoring")
  if LazyVim.pick.picker.name == "telescope" then
    return require("telescope").extensions.refactoring.refactors()
  elseif LazyVim.pick.picker.name == "fzf" then
    require("fzf-lua").fzf_exec(refactoring.get_refactors(), {
      actions = {
        default = function(selected)
          refactoring.refactor(selected[1])
        end,
      },
    })
  else
    refactoring.select_refactor()
  end
end

return {
  {
    "ThePrimeagen/refactoring.nvim",
    -- Newer revisions require Neovim 0.12; this setup intentionally pins 0.11.5.
    commit = "2423b02c400427b9f8d1e28ae3be7da9b291224e",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>r", "", desc = "+refactor", mode = { "n", "x" } },
      { "<leader>rs", pick_refactor, desc = "Refactor", mode = { "n", "x" } },
      {
        "<leader>ri",
        function()
          return require("refactoring").refactor("Inline Variable")
        end,
        desc = "Inline Variable",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rP",
        function()
          require("refactoring").debug.printf({ below = false })
        end,
        desc = "Debug Print",
      },
      {
        "<leader>rp",
        function()
          require("refactoring").debug.print_var({ normal = true })
        end,
        desc = "Debug Print Variable",
        mode = { "n", "x" },
      },
      {
        "<leader>rc",
        function()
          require("refactoring").debug.cleanup({})
        end,
        desc = "Debug Cleanup",
      },
      {
        "<leader>rf",
        function()
          return require("refactoring").refactor("Extract Function")
        end,
        desc = "Extract Function",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rF",
        function()
          return require("refactoring").refactor("Extract Function To File")
        end,
        desc = "Extract Function To File",
        mode = { "n", "x" },
        expr = true,
      },
      {
        "<leader>rx",
        function()
          return require("refactoring").refactor("Extract Variable")
        end,
        desc = "Extract Variable",
        mode = { "n", "x" },
        expr = true,
      },
    },
    opts = { show_success_message = true },
    config = function(_, opts)
      require("refactoring").setup(opts)
      if LazyVim.has("telescope.nvim") then
        LazyVim.on_load("telescope.nvim", function()
          require("telescope").load_extension("refactoring")
        end)
      end
    end,
  },
}
