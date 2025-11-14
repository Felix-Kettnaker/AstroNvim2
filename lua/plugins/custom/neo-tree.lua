return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        mappings = {
          ["a"] = false,
          ["A"] = false,
          ["n"] = { "add", config = { show_path = "none" } },
          ["N"] = "add_directory",
        },
      },
      filesystem = {
        filtered_items = {
          hide_by_pattern = {
            "*.uid",
          },
        },
      },
    },
  },
}
