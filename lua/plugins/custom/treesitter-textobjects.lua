-- Override AstroNvim's nvim-treesitter-textobjects opts.
-- targets.vim-style whitespace handling for the attribute object (aa):
--   daa / yaa  -> include surrounding whitespace (eats the space before the
--                 attribute, or the whole line when it sits alone on one)
--   caa        -> no whitespace, so it clears the attribute in place and leaves
--                 the gap / empty line intact
return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  opts = {
    select = {
      include_surrounding_whitespace = function(o)
        local op = vim.v.operator
        return o.query_string == "@attribute.outer" and op ~= "c" and op ~= ""
      end,
    },
  },
}
