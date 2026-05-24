-- otter.nvim routes LSP requests in mixed-language buffers (JSP here) to the
-- right server based on cursor position. Activated per-buffer from
-- ftplugin/jsp.lua after the treesitter regions are set up.
return {
  "jmbuhr/otter.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function(_, opts)
    require("otter").setup(opts)
    -- Redirect *.jsp otter file paths into a cache dir outside any project so
    -- jdtls treats them as standalone files and runs full semantic analysis
    -- (gd, references, hover). When the otter file lives inside a
    -- jdtls-known project but isn't on its classpath, jdtls reports
    -- "not on the classpath, only syntax errors are reported" and skips
    -- symbol resolution entirely.
    --
    -- otter/init.lua captures path_to_otterpath into a local at module load
    -- time. lazy.nvim's require-hook triggers that capture as soon as any
    -- otter submodule is required, so monkey-patching the source function
    -- doesn't catch the cached reference. Reach into the upvalue instead.
    local cache = vim.fn.stdpath "cache" .. "/jsp-otter"
    vim.fn.mkdir(cache, "p")
    local activate = require("otter").activate
    local orig
    local function patched(path, ext)
      -- ext is the file extension WITH a leading dot, e.g. ".java".
      if path:match "%.jsp$" then
        local stem = vim.fn.fnamemodify(path, ":t"):gsub("[/%s]", "_")
        local hash = vim.fn.sha256(path):sub(1, 8)
        return cache .. "/" .. stem .. "." .. hash .. ".otter" .. ext
      end
      return orig(path, ext)
    end
    local info = debug.getinfo(activate, "u")
    for i = 1, info.nups do
      local name, val = debug.getupvalue(activate, i)
      if name == "path_to_otterpath" then
        orig = val
        debug.setupvalue(activate, i, patched)
        break
      end
    end
  end,
  ---@type otter.config.cfg
  opts = {
    buffers = {
      set_filetype = true,
      -- jdtls won't resolve local variables (gd, references) for an in-memory
      -- LSP-only file; it needs the file on disk to build the project model.
      -- We redirect otter paths into the cache (see init below), so the files
      -- end up in ~/.cache/nvim/jsp-otter — outside neo-tree's view of the
      -- user's project and outside git.
      write_to_disk = true,
    },
    handle_leading_whitespace = true,
    verbose = {
      no_code_found = false,
    },
    -- java is not in otter's default extension map; add it so jdtls picks up
    -- <% %> scriptlets in JSP files.
    extensions = {
      java = "java",
    },
  },
}
