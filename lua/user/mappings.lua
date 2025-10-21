---@diagnostic disable: undefined-global
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {

      -- ====== NORMAL ====== --
      n = {
        -- Mac shortcuts
        ["<D-a>"] = { function() vim.cmd "normal! ggVG" end, desc = "Select all" },
        ["<D-v>"] = { desc = "Paste from clipboard", function() vim.cmd 'normal! "+p' end },
        ["<D-s>"] = {
          desc = "Save file",
          function()
            vim.api.nvim_input "<Esc>"
            vim.cmd "w"
          end,
        },
        ["<D-w>"] = {
          function()
            local bufnr = vim.api.nvim_get_current_buf()
            if vim.fn.bufexists(0) == 1 then
              vim.cmd "b#"
            else
              vim.cmd "bp"
            end
            vim.api.nvim_buf_delete(bufnr, { force = false })
          end,
          desc = "Close tab",
        },

        -- swap jump repeat (, & ;)
        [";"] = { ",", desc = "Repeat Jump backward" },
        [","] = { ";", desc = "Repeat Jump forward" },

        -- move lines
        ["<M-Up>"] = { function() vim.cmd "normal! ddkP==" end, desc = "Move line up reindented" },
        ["<M-Down>"] = { function() vim.cmd "normal! ddp==" end, desc = "Move line down reindented" },

        -- indent lines
        ["<Tab>"] = { ">>", desc = "Indent line" },
        ["<C-i>"] = { "<C-i>", desc = "Jump to next location" }, -- Tab is identical to <C-i> by default
        ["<S-Tab>"] = { "<<", desc = "dedentline" },

        ["gV"] = { "v$h", desc = "Visual nutil EOL" },

        --- Plugin mappings ---
        -- picker
        ["<D-f>"] = { desc = "Find in buffer", function() Snacks.picker.lines() end },
        ["<D-F>"] = { desc = "Find in files", function() Snacks.picker.grep() end },
        ["<D-p>"] = { desc = "Find file", function() Snacks.picker.files() end },

        -- ToggleTerm
        ["<D-b>"] = {
          desc = "Toggle bottom terminal",
          function() vim.cmd("ToggleTerm " .. vim.v.count .. " size=10 direction=horizontal") end,
        },

        --- misc ---
        -- navigate buffer tabs
        ["<C-Tab>"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["<S-C-Tab>"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
      },

      -- ====== INSERT ====== --
      i = {
        ["<D-v>"] = { desc = "Paste from clipboard", "<C-r>+" },
        ["<S-Tab>"] = { "<Cmd>norm! <<<CR>", desc = "dedentline" },
      },

      -- ====== VISUAL ====== --
      v = {
        -- mac shortcuts
        ["<D-c>"] = { '"+y', desc = "Copy to clipboard" },
        ["<D-x>"] = { '"+d', desc = "Cut to clipboard" },
        ["<D-v>"] = { desc = "Paste from clipboard", function() vim.cmd 'normal! "+p' end },

        -- yank without moving cursor
        ["y"] = {
          function()
            local cur = vim.api.nvim_win_get_cursor(0)
            vim.cmd "normal! y"
            vim.api.nvim_win_set_cursor(0, cur)
          end,
        },

        -- move lines in visual line mode
        ["<M-k>"] = { "dkP=']V']", desc = "Move lines up reindented" },
        ["<M-j>"] = { "dp=']V']", desc = "Move lines down reindented" },
      },
    },
  },
}
