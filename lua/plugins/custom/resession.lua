return {
  "stevearc/resession.nvim",
  lazy = true,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>S"] = false
        maps.n["<Leader>Sl"] = false
        maps.n["<Leader>Ss"] = false
        maps.n["<Leader>SS"] = false
        maps.n["<Leader>St"] = false
        maps.n["<Leader>Sd"] = false
        maps.n["<Leader>SD"] = false
        maps.n["<Leader>Sf"] = false
        maps.n["<Leader>SF"] = false
        maps.n["<Leader>S."] = false

        maps.n["<C-s>"] = { desc = vim.tbl_get(opts, "_map_sections", "<c-s>") }
        maps.n["<C-s>l"] = { function() require("resession").load "Last Session" end, desc = "Load last session" }
        maps.n["<C-s>s"] = { function() require("resession").save() end, desc = "Save this session" }
        maps.n["<C-s><C-s>"] = {
          function() require("resession").save(vim.fn.getcwd():match ".*/(.*)$", { dir = "dirsession" }) end,
          desc = "Save this dirsession",
        }
        maps.n["<C-s>t"] = { function() require("resession").save_tab() end, desc = "Save this tab's session" }
        maps.n["<C-s>d"] = { function() require("resession").delete() end, desc = "Delete a session" }
        maps.n["<C-s><C-d>"] =
          { function() require("resession").delete(nil, { dir = "dirsession" }) end, desc = "Delete a dirsession" }
        maps.n["<C-s>f"] = { function() require("resession").load() end, desc = "Load a session" }
        maps.n["<C-s><C-f>"] =
          { function() require("resession").load(nil, { dir = "dirsession" }) end, desc = "Load a dirsession" }
        maps.n["<C-s>."] = {
          function() require("resession").load(vim.fn.getcwd():match ".*/(.*)$", { dir = "dirsession" }) end,
          desc = "Load current dirsession",
        }

        opts.autocmds.resession_auto_save = {
          {
            event = "VimLeavePre",
            desc = "Save session on close",
            callback = function()
              local buf_utils = require "astrocore.buffer"
              local autosave = require("astrocore").config.sessions.autosave
              if autosave and buf_utils.is_valid_session() then
                local save = require("resession").save
                if autosave.last then save("Last Session", { notify = false }) end
                if autosave.cwd then save(vim.fn.getcwd():match ".*/(.*)$", { dir = "dirsession", notify = false }) end
              end
            end,
          },
        }
      end,
    },
  },
}
