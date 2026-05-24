-- Aerial's LSP backend requests document symbols on every buffer with an LSP
-- attached. otter-ls forwards to embedded servers, which on JSP files often
-- aren't ready yet (jdtls takes seconds to index) and yield the noisy
-- "Error requesting document symbols" notification. Restrict aerial to the
-- treesitter backend for jsp so the LSP probe never happens.
return {
  "stevearc/aerial.nvim",
  opts = function(_, opts)
    opts.backends = opts.backends or { "treesitter", "lsp", "markdown", "asciidoc", "man" }
    opts.backends.jsp = { "treesitter" }
    opts.ignore = opts.ignore or {}
    opts.ignore.filetypes = opts.ignore.filetypes or {}
    return opts
  end,
}
