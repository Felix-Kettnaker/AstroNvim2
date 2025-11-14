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
        maps.n["<C-s>S"] = {
          function() require("resession").save(vim.fn.getcwd(), { dir = "dirsession" }) end,
          desc = "Save this dirsession",
        }
        maps.n["<C-s>t"] = { function() require("resession").save_tab() end, desc = "Save this tab's session" }
        maps.n["<C-s>d"] = { function() require("resession").delete() end, desc = "Delete a session" }
        maps.n["<C-s>D"] =
          { function() require("resession").delete(nil, { dir = "dirsession" }) end, desc = "Delete a dirsession" }
        maps.n["<C-s>f"] = { function() require("resession").load() end, desc = "Load a session" }
        maps.n["<C-s>F"] =
          { function() require("resession").load(nil, { dir = "dirsession" }) end, desc = "Load a dirsession" }
        maps.n["<C-s><C-f>"] =
          { function() require("resession").load(nil, { dir = "dirsession" }) end, desc = "Load a dirsession" }
        maps.n["<C-s>."] = {
          function() require("resession").load(vim.fn.getcwd(), { dir = "dirsession" }) end,
          desc = "Load current dirsession",
        }
      end,
    },
  },
}
