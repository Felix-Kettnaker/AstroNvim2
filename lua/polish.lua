-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- disale graying out "unnecessary" code (sometimes entire functions)
vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { link = "NONE" })
