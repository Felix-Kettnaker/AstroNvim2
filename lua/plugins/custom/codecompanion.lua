return {
  "olimorris/codecompanion.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    strategies = {
      chat = {
        name = "copilot",
        model = "gemini-3-pro-preview",
      },
      keymaps = {
        send = {
          modes = {
            i = "<D-CR>",
          },
        },
      },
    },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<D-r>"] = { function() vim.cmd "CodeCompanionChat Toggle" end, desc = "Open AI Chat Window" }
        maps.n["<D-i>"] = { ":CodeCompanion #{buffer}", desc = "Ask AI inline" }
        maps.v["<D-i>"] = { ":CodeCompanion #{buffer}", desc = "Ask AI inline" }
      end,
    },
  },
}
