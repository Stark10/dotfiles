return {
  {
    "folke/sidekick.nvim",
    opts = {
      -- Keep Copilot completions independent; Sidekick owns only the CLI workflow.
      nes = { enabled = false },
      cli = {
        tools = {
          omp = {
            cmd = { "omp" },
            is_proc = "\\<omp\\>",
            url = "https://github.com/can1357/oh-my-pi",
            resume = { "--resume" },
            continue = { "--continue" },
            native_scroll = false,
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ name = "omp" })
        end,
        desc = "Toggle Oh My Pi",
      },
    },
  },
}
