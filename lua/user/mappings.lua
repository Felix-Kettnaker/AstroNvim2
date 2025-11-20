local shared = {
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
  ["<D-s>"] = {
    desc = "Save file",
    function()
      vim.api.nvim_input "<Esc>"
      vim.cmd "w"
    end,
  },
  ["<F2>"] = { function() vim.lsp.buf.rename() end, desc = "Rename current symbol" },

  ["<C-Tab>"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
  ["<S-C-Tab>"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

  -- ToggleTerm
  ["<D-b>"] = {
    desc = "Toggle bottom terminal",
    function() vim.cmd("ToggleTerm " .. vim.v.count .. " size=10 direction=horizontal") end,
  },

  -- deletion in insert mode
  ["<D-Backspace>"] = { "<Cmd>norm! d0<CR>", desc = "Delete to start of line" },
  ["<D-Delete>"] = { "<Cmd>norm! ld$<CR>", desc = "Delete to end of line" },
  ["<M-Backspace>"] = { "<Cmd>norm! db<CR>", desc = "Delete word backwards" },
  ["<M-Delete>"] = { "<Cmd>norm! dw<CR>", desc = "Delete word forwards" },
}

---@diagnostic disable: undefined-global
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    _map_sections = {
      ["<c-s>"] = { desc = require("astroui").get_icon("Session", 1, true) .. "Session" },
    },
    mappings = {

      -- ====== NORMAL ====== --
      n = {
        -- Mac shortcuts
        ["<D-a>"] = { function() vim.cmd "normal! ggVG" end, desc = "Select all" },
        ["<D-v>"] = { desc = "Paste from clipboard", function() vim.cmd 'normal! "+p' end },
        ["<D-s>"] = shared["<D-s>"],
        ["<D-w>"] = shared["<D-w>"],

        ["<F2>"] = shared["<F2>"],

        -- swap jump repeat (, & ;)
        [";"] = { ",", desc = "Repeat Jump backward" },
        [","] = { ";", desc = "Repeat Jump forward" },

        -- move lines
        ["<M-Up>"] = { function() vim.cmd "normal! ddkP==" end, desc = "Move line up reindented" },
        ["<M-Down>"] = { function() vim.cmd "normal! ddp==" end, desc = "Move line down reindented" },

        -- indent lines
        ["<C-i>"] = { "<C-i>", desc = "Jump to next location" }, -- Tab is identical to <C-i> by default
        ["<Tab>"] = { ">>", desc = "Indent line" },
        ["<S-Tab>"] = { "<<", desc = "dedentline" },
        ["=p"] = { "=']", desc = "Reindent pasted text" },

        ["gV"] = { "v$h", desc = "Visual nutil EOL" },

        --- Plugin mappings ---
        -- picker
        ["<D-f>"] = { desc = "Find in buffer", function() require("snacks").picker.lines() end },
        ["<D-F>"] = { desc = "Find in files", function() require("snacks").picker.grep() end },
        ["<D-p>"] = { desc = "Find file", function() require("snacks").picker.files() end },

        -- ToggleTerm
        ["<D-b>"] = shared["<D-b>"],

        --- misc ---
        -- navigate buffer tabs
        ["<C-Tab>"] = shared["<C-Tab>"],
        ["<S-C-Tab>"] = shared["<S-C-Tab>"],

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- "Language" mappings
        ["<Leader>lt"] = {
          function()
            vim.ui.input({ prompt = "New Filetype:" }, function(input)
              if not input or input == "" then
                vim.notify("Filetype was not set.", vim.log.levels.WARN)
                return
              end
              vim.cmd("set filetype=" .. input)
            end)
          end,
          desc = "Set filetype of buffer",
        },
      },

      -- ====== INSERT ====== --
      i = {
        ["<D-v>"] = { desc = "Paste from clipboard", "<C-r>+" },
        ["<D-s>"] = shared["<D-s>"],
        ["<D-w>"] = shared["<D-w>"],

        ["<F2>"] = shared["<F2>"],

        -- change indentation
        ["<S-Tab>"] = { "<Cmd>norm! <<hh<CR>", desc = "dedent line" },
        -- ["<Tab>"] = { "<Cmd>norm! >>ll<CR>", desc = "indent line" },

        -- navigate buffer tabs
        ["<C-Tab>"] = shared["<C-Tab>"],
        ["<S-C-Tab>"] = shared["<S-C-Tab>"],

        -- deletion in insert mode
        ["<D-Backspace>"] = shared["<D-Backspace>"],
        ["<D-Delete>"] = shared["<D-Delete>"],
        ["<M-Backspace>"] = shared["<M-Backspace>"],
        ["<M-Delete>"] = shared["<M-Delete>"],
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
        ["<M-Up>"] = { "dkP=']V']", desc = "Move lines up reindented" },
        ["<M-Down>"] = { "dp=']V']", desc = "Move lines down reindented" },
      },

      -- ====== TERMINAL ====== --
      t = {
        ["<D-b>"] = shared["<D-b>"],
        ["<C-w>"] = { "<C-\\><C-n><C-w>", desc = "Window (from terminal)" },
        ["<D-Esc>"] = { "<C-\\><C-n>", desc = "Exit terminal mode" },
        ["<D-v>"] = { '<C-\\><C-n>"+pi', desc = "Paste from clipboard" },

        -- deletion in insert mode
        ["<D-Backspace>"] = shared["<D-Backspace>"],
        ["<D-Delete>"] = shared["<D-Delete>"],
        ["<M-Backspace>"] = shared["<M-Backspace>"],
        ["<M-Delete>"] = shared["<M-Delete>"],
      },

      -- ====== COMMAND ====== --
      c = {
        ["<D-v>"] = { "<C-r>+", desc = "Paste from clipboard" },

        -- navigation asdasd asdd
        ["<D-Right>"] = { "<C-E>", desc = "Jump to End of Line" },
        ["<M-Right>"] = { "<S-Right>", desc = "Jump one Word right" },
        ["<D-Left>"] = { "<C-B>", desc = "Jump to End of Line" },
        ["<M-Left>"] = { "<S-Left>", desc = "Jump one Word left" },
        -- deletion
        ["<D-Backspace>"] = { "<C-u>", desc = "Delete to start of line" },
        -- ["<D-Delete>"] = shared["<D-Delete>"],
        ["<M-Backspace>"] = { "<C-w>", desc = "Delete word backwards" },
        -- ["<M-Delete>"] = shared["<M-Delete>"],
      },
    },
  },
}
