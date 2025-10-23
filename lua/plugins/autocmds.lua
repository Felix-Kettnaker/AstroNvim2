---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroLSPOpts
  opts = {
    autocmds = {

      prevent_comment_extension = {
        {
          event = { "BufEnter" },
          desc = "prevents adding the comment prefix when pressing o on a commented line, enter works though",
          callback = function() vim.opt.formatoptions:remove { "o" } end,
        },
      },

      set_filetypes = {
        {
          event = { "BufRead", "BufNewFile" },
          desc = "sets the filetype of all .env* files to sh",
          pattern = ".env*",
          command = "set filetype=sh",
        },
      },
    },
  },
}
