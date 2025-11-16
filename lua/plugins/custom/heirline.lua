return {
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      local statusline = opts.statusline
      local status = require "astroui.status"

      -- Add file path component to statusline
      local file_info = {
        provider = function()
          local path_full = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
          local path = string.sub(path_full, 0, 64)
          if string.len(path) < string.len(path_full) then path = "..." .. path end
          if vim.bo.filetype == "toggleterm" then
            local bufname = vim.api.nvim_buf_get_name(0)
            local term_num = bufname:match "#toggleterm#(%d+)"
            return "󰆍 Term " .. (term_num or "?") .. " "
          end
          if vim.bo.filetype == "neo-tree" then return "🌳" end
          if path == "" then return "" end
          return "󰉋 " .. path .. " "
        end,
        hl = { fg = "#89B4FA" }, -- Catppuccin blue
      }

      -- Insert after the "file_info" block
      table.insert(statusline, 4, file_info)
      statusline[13] = status.component.nav { percentage = false, scrollbar = false }
      return opts
    end,
  },
}
