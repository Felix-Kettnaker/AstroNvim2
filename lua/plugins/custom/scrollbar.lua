return {
  {
    "petertriho/nvim-scrollbar",
    config = function()
      local colors = require("catppuccin.palettes").get_palette "mocha"
      require("scrollbar").setup {
        show_in_active_only = true,
        hide_if_all_visible = true,
        excluded_buftypes = {
          "neo-tree",
        },
        handlers = {
          cursor = false,
        },

        handle = {
          color = colors.surface1,
        },
      }
    end,
  },
}
