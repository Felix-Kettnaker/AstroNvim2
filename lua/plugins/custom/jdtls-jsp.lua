-- Make jdtls's root_dir per-buffer instead of once at plugin load.
--
-- astrocommunity's java pack snapshots opts.root_dir = vim.fs.root(0, ...)
-- when the plugin's `opts` function runs and uses that single value for every
-- subsequent buffer. For JSP otter buffers placed in ~/.cache/nvim/jsp-otter,
-- the snapshotted project root is wrong, and jdtls then refuses to analyze
-- ("Given URI does not belong to any Java project" -> empty defs/refs).
--
-- Override the FileType=java autocmd: compute root_dir on each java buffer
-- open, walking up from the file. The otter cache dir gets a marker .git
-- so the search anchors there for jsp otter files.
return {
  "mfussenegger/nvim-jdtls",
  config = function(_, opts)
    local otter_cache = vim.fn.stdpath "cache" .. "/jsp-otter"
    vim.fn.mkdir(otter_cache, "p")

    -- astrocommunity registers its FileType=java autocmd without a named
    -- group, so nuke every matching one before installing ours.
    pcall(vim.api.nvim_clear_autocmds, { event = "FileType", pattern = "java" })
    local group = vim.api.nvim_create_augroup("nvim_jdtls_filetype", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "java",
      callback = function(args)
        local cfg = vim.deepcopy(opts)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if vim.startswith(bufname, otter_cache .. "/") then
          cfg.root_dir = otter_cache
        else
          cfg.root_dir = vim.fs.root(args.buf, { ".git", "mvnw", "gradlew" }) or vim.fn.fnamemodify(bufname, ":h")
        end
        require("jdtls").start_or_attach(cfg)
      end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = group,
      pattern = "*.java",
      callback = function(a)
        local client = vim.lsp.get_client_by_id(a.data.client_id)
        if client and client.name == "jdtls" then
          pcall(function() require("jdtls.dap").setup_dap_main_class_configs() end)
        end
      end,
    })
  end,
}
