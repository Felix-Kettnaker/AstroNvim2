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

      -- Custom tab label: index.* → [parent].ext, max 26 chars with middle ellipsis
      local function tab_fname(bufnr)
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path == "" then return "" end
        local name = vim.fn.fnamemodify(path, ":t")
        local stem, ext = name:match("^(.+)%.([^%.]+)$")
        if stem == "index" and ext then
          local parent = vim.fn.fnamemodify(path, ":h:t")
          if parent ~= "" and parent ~= "." then
            name = "[" .. parent .. "]." .. ext
          end
        end
        local max = 26
        local len = vim.fn.strcharlen(name)
        if len > max then
          local left = math.floor((max - 1) / 2)
          local right = max - 1 - left
          name = vim.fn.strcharpart(name, 0, left) .. "…" .. vim.fn.strcharpart(name, len - right, right)
        end
        return name
      end

      opts.tabline[2] = status.heirline.make_buflist(
        status.component.tabline_file_info {
          filename = { fname = tab_fname },
          -- Use the transformed display name for clash detection so that
          -- e.g. [i18n].idx.js vs [api].idx.js are not considered duplicates.
          unique_path = { buf_name = tab_fname },
        }
      )

      return opts
    end,
  },
}
