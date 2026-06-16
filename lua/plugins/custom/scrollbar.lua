return {
  {
    -- Floating-window scrollbar (not buffer extmarks), so it stays put under
    -- neovide's smooth scroll instead of animating along with the content.
    "dstein64/nvim-scrollview",
    event = "User AstroFile",
    opts = {
      current_only = true,
      excluded_filetypes = { "neo-tree" },
      -- 'simple' = line-based; skips the per-refresh virtual-line recompute that
      -- 'auto'/'proper' does, which makes scrolling choppy under neovide.
      mode = "simple",
      -- 'overflow' (default): hide the bar when the whole buffer fits on screen.
      signs_on_startup = { "conflicts", "diagnostics" },
    },
    config = function(_, opts)
      require("scrollview").setup(opts)
      local colors = require("catppuccin.palettes").get_palette "mocha"
      vim.api.nvim_set_hl(0, "ScrollView", { bg = colors.surface1 })
    end,
  },
}
