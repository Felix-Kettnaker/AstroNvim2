---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroLSPOpts
  opts = {
    autocmds = {

      prevent_comment_extension = {
        {
          event = { "BufRead", "BufEnter" },
          desc = "prevents adding the comment prefix when pressing o on a commented line, enter works though",
          callback = function() vim.opt.formatoptions:remove { "o" } end,
        },
      },

      init_by_filetype = {
        { -- set filetype
          event = { "BufRead", "BufNewFile" },
          desc = "sets the filetype of all .env* files to sh",
          pattern = ".env*",
          command = "set filetype=sh",
        },
        { -- set wrap
          event = { "BufRead", "BufNewFile" },
          desc = "enable line wrap for markdown and text files",
          pattern = { "*.md", "*.txt", "*.markdown" },
          command = "setlocal wrap",
        },
      },
    },
  },
}
