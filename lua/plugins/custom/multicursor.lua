return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require "multicursor-nvim"
      mc.setup()

      -- Mappings defined in a keymap layer only apply when there are
      -- multiple cursors. This lets you have overlapping mappings.
      mc.addKeymapLayer(function(layerSet)
        -- Delete the main cursor.
        -- layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)

        -- Enable and clear cursors using escape.
        layerSet("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { bg = "#FFFFAA", fg = "#332222" })
    end,
    keys = {
      {
        "<C-LeftMouse>",
        function() require("multicursor-nvim").handleMouse() end,
        mode = "n",
        desc = "Add/Remove Cursor",
      },
      {
        "<C-LeftDrag>",
        function() require("multicursor-nvim").handleMouseDrag() end,
        mode = "n",
        desc = "Add cursor (drag)",
      },
      {
        "<C-LeftRelease>",
        function() require("multicursor-nvim").handleMouseRelease() end,
        mode = "n",
        desc = "Finish cursor drag",
      },
      {
        "<D-k>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.lineAddCursor(-1)
          end
        end,
        mode = "n",
        desc = "󰞙 Add Cursor above",
      },
      {
        "<D-j>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.lineAddCursor(1)
          end
        end,
        mode = "n",
        desc = "󰞖 Add Cursor below",
      },
      {
        "<D-M-k>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.lineSkipCursor(-1)
          end
        end,
        mode = "n",
        desc = " Skip Cursor above",
      },
      {
        "<D-M-j>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.lineSkipCursor(1)
          end
        end,
        mode = "n",
        desc = " Skip Cursor below",
      },
      {
        "<D-n>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.matchAddCursor(1)
          end
        end,
        mode = "n",
        desc = "󰞘 Add Cursor next match",
      },
      {
        "<D-N>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.matchAddCursor(-1)
          end
        end,
        mode = "n",
        desc = "󰞗 Add Cursor prev match",
      },
      {
        "<D-M-n>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.matchSkipCursor(1)
          end
        end,
        mode = "n",
        desc = " Skip Cursor next match",
      },
      {
        "<D-M-N>",
        function()
          local mc = require "multicursor-nvim"
          for _ = 1, vim.v.count1 do
            mc.matchSkipCursor(-1)
          end
        end,
        mode = "n",
        desc = " Skip Cursor prev match",
      },
      {
        "<D-*>",
        function() require("multicursor-nvim").matchAllAddCursors() end,
        mode = "n",
        desc = "󰎂 Add Cursor every match",
      },
    },
  },
}
