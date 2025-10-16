
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    n = {
      -- navigate buffer tabs
      ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
      ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

      -- mappings seen under group name "Buffer"
      ["<Leader>bd"] = {
        function()
          require("astroui.status.heirline").buffer_picker(
            function(bufnr) require("astrocore.buffer").close(bufnr) end
          )
        end,
        desc = "Close buffer from tabline",
      },
    }
  }
}
