return {
  {
    "kylechui/nvim-surround",
    opts = {
      keymaps = {
        normal = "<Leader>s",
        normal_cur = "<Leader>sl", -- surround current line
        normal_line = "<Leader>S", -- surround on new lines (above+bellow)
        normal_cur_line = "<Leader>Sl",
        visual = "<Leader>s",
        visual_line = "<Leader>S",
      },
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
