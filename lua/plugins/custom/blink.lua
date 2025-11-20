local keymap = {
  ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
  ["<Tab>"] = { "accept", "fallback" },
  ["<Right>"] = { "accept", "fallback" },
  ["<S-CR>"] = { "accept_and_enter", "fallback" },
  ["<S-Tab>"] = false,
  ["<C-f>"] = { function(cmp) cmp.select_next { auto_insert = false, count = 5 } end },
  ["<C-b>"] = { function(cmp) cmp.select_prev { auto_insert = false, count = 5 } end },
  ["<Down>"] = { function(cmp) return cmp.select_next { auto_insert = false } end, "fallback" },
  ["<Up>"] = { function(cmp) return cmp.select_prev { auto_insert = false } end, "fallback" },
}
return {
  {
    "Saghen/blink.cmp",
    opts = {
      keymap = keymap,
      cmdline = {
        keymap = keymap,
        completion = { menu = { auto_show = true } },
      },
    },
  },
}
