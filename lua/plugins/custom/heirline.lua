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

      -- ===== toggleterm terminal tab bar (winbar) =====
      -- Allow heirline's winbar on non-floating toggleterm windows (AstroNvim
      -- disables it for buftype=terminal); floats stay bare.
      local astro_disable_winbar = opts.opts.disable_winbar_cb
      opts.opts.disable_winbar_cb = function(args)
        if vim.bo[args.buf].filetype == "toggleterm" then
          return vim.api.nvim_win_get_config(0).relative ~= ""
        end
        return astro_disable_winbar(args)
      end

      -- One tab per terminal, styled like the buffer tabline. We build children
      -- ourselves instead of heirline's make_buflist: that helper is meant for
      -- the single global tabline and decides the active tab from
      -- vim.g.actual_curbuf (only set during statusline/tabline eval, not
      -- winbar), so in a per-window winbar it dropped/blanked tabs. Here the
      -- drawn window's current buffer is the source of truth for "active".
      local status_utils = require "astroui.status.utils"
      local term_tabs = require "term-tabs"

      -- a single terminal's tab, styled active/inactive like a buffer tab
      local function make_tab(bufnr, active)
        local key = active and "buffer_active" or "buffer"
        return status_utils.surround(
          "tab",
          { main = key .. "_bg", left = "tabline_bg", right = "tabline_bg" },
          {
            on_click = {
              callback = function(_, minwid) require("term-tabs").click(minwid) end,
              minwid = bufnr,
              name = "heirline_term_tab_click",
            },
            provider = function()
              local term = require("toggleterm.terminal").get(vim.b[bufnr].toggle_number, true)
              return term and term_tabs.label(term) or ""
            end,
            hl = status.hl.get_attributes(key, true),
          },
          function() return vim.api.nvim_buf_is_valid(bufnr) end
        )
      end

      table.insert(opts.winbar, 1, {
        condition = function() return vim.bo.filetype == "toggleterm" end,
        { -- the tab list: rebuild children each draw from the live terminal set
          init = function(self)
            local cur = vim.api.nvim_get_current_buf()
            local bufs = term_tabs.bufs()
            for i, bufnr in ipairs(bufs) do
              if not (self[i] and self[i].bufnr == bufnr and self[i].active == (bufnr == cur)) then
                self[i] = self:new(make_tab(bufnr, bufnr == cur), i)
                self[i].bufnr, self[i].active = bufnr, bufnr == cur
              end
            end
            for i = #bufs + 1, #self do
              self[i] = nil
            end
          end,
        },
        status.component.fill { hl = { bg = "tabline_bg" } },
      })

      return opts
    end,
  },
}
