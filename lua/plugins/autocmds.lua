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

      update_neovide_title = {
        {
          event = { "User", "DirChanged", "VimEnter" },
          desc = "changes vim.opt.titlestring to display the dirsession",
          pattern = { "ResessionLoadPost", "*" },
          callback = function()
            vim.schedule(function()
              local session = vim.g.current_session_name or "No Session"
              local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
              -- Format: [Session] - CWD - Neovide
              if session == "No Session" then
                vim.opt.titlestring = "Neovide"
              else
                vim.opt.titlestring = string.format("[%s] 🔸 %s", session, cwd)
              end
            end)
          end,
        },
      },
    },
  },
}
