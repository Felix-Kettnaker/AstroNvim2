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

      attribute_textobject = {
        {
          event = "FileType",
          desc = "map aa/ia to the attribute text object in markup files (falls back to argument)",
          pattern = { "html", "xml", "vue" },
          callback = function(args)
            -- AstroNvim binds buffer-local aa/ia to @parameter (argument) via
            -- nvim-treesitter-textobjects; it does so on FileType too, so defer
            -- to override it after.
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(args.buf) then return end
              local select = require("nvim-treesitter-textobjects.select").select_textobject
              local shared = require "nvim-treesitter-textobjects.shared"
              local scfg = require("nvim-treesitter-textobjects.config").select
              -- attribute object, falling back to the argument object when the
              -- cursor isn't on/before an attribute (preserves the old aa/ia).
              local function map(lhs, attr_obj, arg_obj)
                vim.keymap.set({ "x", "o" }, lhs, function()
                  local hit = shared.textobject_at_point(
                    "@attribute.outer",
                    "attributes",
                    0,
                    nil,
                    { lookahead = scfg.lookahead, lookbehind = scfg.lookbehind }
                  )
                  if hit then
                    select(attr_obj, "attributes")
                  else
                    select(arg_obj, "textobjects")
                  end
                end, {
                  buffer = args.buf,
                  desc = "attribute/argument " .. (lhs == "aa" and "outer" or "inner"),
                })
              end
              map("aa", "@attribute.outer", "@parameter.outer")
              map("ia", "@attribute.inner", "@parameter.inner")
            end)
          end,
        },
      },

      term_tabbar = {
        {
          event = { "TermOpen", "TermClose" },
          desc = "refresh the terminal tab bar in all visible winbars",
          callback = function() vim.cmd "redrawstatus!" end,
        },
        {
          event = "BufWinEnter",
          desc = "keep non-terminal buffers out of the terminal split (redirect to editor)",
          callback = function(args) require("term-tabs").keep_terminal(args.buf) end,
        },
        {
          event = "FileType",
          pattern = "toggleterm",
          desc = "capture submitted command as the terminal tab label",
          callback = function(args)
            vim.keymap.set("t", "<CR>", function()
              require("term-tabs").capture()
              return vim.keycode "<CR>"
            end, { buffer = args.buf, expr = true, desc = "Submit (update terminal tab label)" })
          end,
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
