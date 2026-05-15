return {
  "Wansmer/treesj",
  opts = function(_, opts)
    opts.use_default_keymaps = false
    opts.max_join_length = 160

    local utils = require('treesj.langs.utils')
    local ternary = utils.set_preset_for_non_bracket({
      both = {
        omit = {
          function(tsj)
            local prev = tsj:tsnode():prev_sibling()
            -- first child (condition) -> stay on the opening line
            if prev == nil then return true end
            -- consequence / alternative -> stay attached to ? or :
            local t = prev:type()
            return t == '?' or t == ':'
          end,
        },
      },
      split = {
        last_indent = 'inner',
      },
    })
    opts.langs = vim.tbl_deep_extend('force', opts.langs or {}, {
      javascript = { ternary_expression = ternary },
      typescript = { ternary_expression = ternary },
      tsx        = { ternary_expression = ternary },
    })
  end,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<leader>j"] = { function() require("treesj").toggle() end, desc = "Toggle Split/Join" }
      end,
    },
  },
}
