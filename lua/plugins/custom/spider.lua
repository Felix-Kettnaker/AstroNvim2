return {
  "chrisgrieser/nvim-spider",
  opts = { skipInsignificantPunctuation = true },
  keys = {
    { "<M-w>", function() require("spider").motion "w" end, mode = { "n", "x", "o" }, desc = "Subword forward" },
    { "<M-b>", function() require("spider").motion "b" end, mode = { "n", "x", "o" }, desc = "Subword back" },
    { "<M-e>", function() require("spider").motion "e" end, mode = { "n", "x", "o" }, desc = "Subword end" },
    { "€", function() require("spider").motion "e" end, mode = { "n", "x", "o" }, desc = "Subword end" },
    { "g<M-e>", function() require("spider").motion "ge" end, mode = { "n", "x", "o" }, desc = "Subword start" },
    { "g€", function() require("spider").motion "ge" end, mode = { "n", "x", "o" }, desc = "Subword start" },
  },
}
