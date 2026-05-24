return {
  dir = "~/Documents/Privat/Nvim/region-highlight",
  event = "BufReadPost",
  -- "Felix-Kettnaker/region-highlight.nvim",
  -- #region opts
  -- region
  opts = {
    refresh_debounce = 50,
    fold_all = false,
    colors = { "#202230", "#212733", "#232c36", "#253238" },
  }, -- endregion
  -- #endregion
  keys = {
    {
      "<Leader>fR",
      function() vim.cmd "RegionPickerGlobal" end,
      mode = "n",
      desc = "Pick Region (Global)",
    },
    {
      "<Leader>f<C-r>",
      function() vim.cmd "RegionPickerBuf" end,
      mode = "n",
      desc = "Pick Region (Buffer)",
    },
  },
}
