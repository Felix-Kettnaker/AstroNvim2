return {
  "LintaoAmons/scratch.nvim",
  config = function()
    require("scratch").setup {
      use_telescope = false,
      file_picker = "snacks",
    }
  end,
  event = "VeryLazy",
  keys = {
    {
      "<Leader>N",
      "<cmd>ScratchWithName<cr>",
      mode = "n",
      desc = "New named Scratch Buffer",
    },
    {
      "<Leader>fs",
      "<cmd>ScratchOpen<cr>",
      mode = "n",
      desc = "Find Scratch Buffer",
    },
  },
}
