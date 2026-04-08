return {
  {
    "kylechui/nvim-surround",
    keys = {
      {
        "<Leader>s",
        "<Plug>(nvim-surround-normal)",
        mode = "n",
        desc = "Add a surrounding pair around a motion",
      },
      {
        "<Leader>sl",
        "<Plug>(nvim-surround-normal-cur)",
        mode = "n",
        desc = "Add a surrounding pair around the current line",
      },
      {
        "<Leader>S",
        "<Plug>(nvim-surround-normal-line)",
        mode = "n",
        desc = "Add a surrounding pair around a motion, on new lines",
      },
      {
        "<Leader>Sl",
        "<Plug>(nvim-surround-normal-cur-line)",
        mode = "n",
        desc = "Add a surrounding pair around the current line, on new lines",
      },
      {
        "<Leader>s",
        "<Plug>(nvim-surround-normal-visual)",
        mode = "x",
        desc = "Add a surrounding pair around a visual selection",
      },
      {
        "<Leader>S",
        "<Plug>(nvim-surround-normal-visual-line)",
        mode = "x",
        desc = "Add a surrounding pair around a visual selection, on new lines",
      },
    },
    opts = {
      surrounds = {
        ["/"] = {
          add = { " /* ", " */ " },
          find = " ?/%* ?.- ?%*/ ?",
          delete = "^( ?/%* ?)().-( ?%*%/ ?)()$",
        },
        ["!"] = {
          add = { "<!-- ", " -->" },
          find = " ?<!%-%- ?.- ?%-%-> ?",
          delete = "^( ?<!%-%- ?)().-( ?%-%-> ?)()$",
        },
        ["s"] = {
          add = function()
            local language = vim.bo.filetype
            local is_jsy = (language == "javascript" or language == "typescript" or language == "vue")

            if is_jsy then return { { "`${" }, { "}`" } } end
          end,
        },
        ["S"] = {
          add = function()
            local language = vim.bo.filetype
            local is_jsy = (language == "javascript" or language == "typescript" or language == "vue")

            if is_jsy then
              vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes(
                  "<Plug>(nvim-surround-change)q`",
                  true, -- Do not replace CSI.
                  false, -- Do not replace key codes (e.g., <CR>).
                  true -- Escape special key codes for the terminal.
                ),
                "n", -- Mode: 'n' for normal, 'x' for visual, etc.
                true -- remap: true to process mappings
              )
              return { { "${" }, { "}" } }
            end
          end,
        },
      },
      aliases = {
        ["b"] = { "}", "]", ")", ">" },
      },
    },
  },
}
