return {
  "Wansmer/treesj",
  opts = {
    use_default_keymaps = false,
    max_join_length = 160,
  },
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
