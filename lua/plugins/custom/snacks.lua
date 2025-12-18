return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    input = {
      -- prompt_pos = false,
    },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        local snack_opts = require("astrocore").plugin_opts "snacks.nvim"

        maps.n["<Leader>ft"] = nil
        maps.n["<Leader>f<C-t>"] = { function() require("snacks").picker.colorschemes() end, desc = "Find themes" }
      end,
    },
  },
}
