return {
  "chrisgrieser/nvim-various-textobjs",
  keys = {
    { "i<M-w>", function() require("various-textobjs").subword "inner" end, mode = { "x", "o" }, desc = "Inner subword" },
    { "a<M-w>", function() require("various-textobjs").subword "outer" end, mode = { "x", "o" }, desc = "Around subword" },
    { "iz", function() require("various-textobjs").number "inner" end, mode = { "x", "o" }, desc = "Inner number (Zahl)" },
    { "az", function() require("various-textobjs").number "outer" end, mode = { "x", "o" }, desc = "Outer number (Zahl)" },
  },
}
