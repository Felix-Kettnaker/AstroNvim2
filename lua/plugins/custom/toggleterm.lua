local M = {}

return {
  "akinsho/toggleterm.nvim",
  keys = {
    -- Map your leader key here
    {
      "<leader>tc",
      function()
        M.copilot_tui.toggle_tui()
        vim.defer_fn(function() vim.cmd "startinsert" end, 10)
      end,
      desc = "Toggle Copilot",
    },
  },
  config = function()
    require("toggleterm").setup {
      -- Your general toggleterm settings here
      start_in_insert = true,
    }

    -- Define your TUI terminal persistently
    local Terminal = require("toggleterm.terminal").Terminal
    local copilot_tui = Terminal:new {
      cmd = "copilot --resume",
      direction = "float",
      float_opts = { border = "curved" },
      -- Ensure it starts in insert mode
      start_in_insert = true,
    }

    -- Expose a toggle function globally or in a local module
    M.copilot_tui = {
      toggle_tui = function() copilot_tui:toggle() end,
    }
  end,
}
