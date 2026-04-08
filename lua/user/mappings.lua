require "user.commands"

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
  -- ["<F2>"] = {
  --   function()
  --     local curr_word = vim.fn.expand "<cword>"
  --     vim.ui.input({ prompt = "Rename '" .. curr_word .. "' to: " }, function(input)
  --       if input and #input > 0 then vim.lsp.buf.rename(input) end
  --     end)
  --   end,
  --   desc = "Rename current symbol",
  -- },

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
        ["<Leader><D-s>"] = {
          desc = "Save file without formatting",
          function()
            vim.api.nvim_input "<Esc>"
            vim.cmd "noautocmd w"
          end,
        },

        ["<F2>"] = shared["<F2>"],

        -- move lines
        ["<M-Up>"] = { function() vim.cmd "normal! ddkP==" end, desc = "Move line up reindented" },
        ["<M-Down>"] = { function() vim.cmd "normal! ddp==" end, desc = "Move line down reindented" },

        -- indent lines
        ["<C-i>"] = { "<C-i>", desc = "Jump to next location" }, -- Tab is identical to <C-i> by default
        ["<Tab>"] = { ">>", desc = "Indent line" },
        ["<S-Tab>"] = { "<<", desc = "dedentline" },
        ["=p"] = { "=']", desc = "Reindent pasted text" },

        ["gV"] = { "v$h", desc = "Visual nutil EOL" },

        --- Overridden vim cpmmands ---
        -- swap jump repeat (, & ;)
        [";"] = { ",", desc = "Repeat Jump backward" },
        [","] = { ";", desc = "Repeat Jump forward" },
        ["Vat"] = { "VatV", desc = "Visual line around tag" },

        ["gp"] = { "`[v`]", desc = "Visual select last paste" },

        --- Custom Commands ---
        ["<Leader>c"] = { desc = "Execute a custom Command" },
        ["<Leader>cs"] = { function() vim.cmd 'SplitLineAt " "' end, desc = "Split current line at Spaces" },
        ["<Leader>cS"] = { function() vim.cmd "SplitLineAt" end, desc = "Split current line at provided delimiter" },

        --- Plugin mappings ---
        -- picker
        ["<D-f>"] = { desc = "Find in buffer", function() require("snacks").picker.lines() end },
        ["<D-F>"] = { desc = "Find in files", function() require("snacks").picker.grep() end },
        ["<D-p>"] = { desc = "Find file", function() require("snacks").picker.files() end },
        ["<Leader>fj"] = { desc = "Find Jumps", function() require("snacks").picker.jumps() end },
        ["<Leader>fS"] = { desc = "Find NPM Scripts", function() vim.cmd "PickNpmScript" end },
        ["<Leader>ft"] = { desc = "Find Terminals", function() vim.cmd "PickTerminal" end },

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

        -- LSP mappings
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
        ["<Leader>lu"] = {
          function() require("snacks").picker.lsp_references { auto_confirm = false } end,
          desc = "search Usages",
        },
      },

      -- ====== INSERT ====== --
      i = {
        ["<D-v>"] = { desc = "Paste from clipboard", "<C-r>+" },
        ["<D-s>"] = shared["<D-s>"],
        ["<D-w>"] = shared["<D-w>"],

        ["<F2>"] = shared["<F2>"],

        -- ToggleTerm
        ["<D-b>"] = shared["<D-b>"],

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
            -- Yank to the specified register if a register is given
            local reg = vim.v.register
            if reg and reg ~= '"' then
              vim.cmd('normal! "' .. reg .. "y")
            else
              vim.cmd "normal! y"
            end
            vim.api.nvim_win_set_cursor(0, cur)
          end,
        },
        -- search selection
        ["/"] = { "y/<C-r>0", desc = "Search selection" },
        ["<D-f>"] = { "y:lua Snacks.picker.lines()<CR><C-r>0", desc = "Search line with selection" },

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
