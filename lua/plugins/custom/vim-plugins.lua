return {
  {
    "azabiong/vim-highlighter",
    init = function()
      vim.cmd [[
        " directory to store highlight files
        let HiKeywords = '~/.config/nvim-astronvim/vim-highlighter'
        hi HiColor30 guifg=#3bcc34 guibg=#232e34 gui=bold
        hi HiColor31 guifg=#ca3734 guibg=#322235 gui=bold
        hi HiColor32 guifg=#2cc787 guibg=#273340 gui=bold
        hi HiColor33 guifg=#d1286f guibg=#392c43 gui=bold
        hi HiColor34 guifg=#99da6b guibg=#253034 gui=bold
        hi HiColor35 guifg=#f16556 guibg=#322336 gui=bold
        hi HiColor36 guifg=#f99b54 guibg=#31242f gui=bold
        hi HiColor37 guifg=#298cf4 guibg=#1e2d46 gui=bold
        let HiClear = 'f<S-BS>'
      ]]
    end,
  },
  {
    "wellle/targets.vim",
    init = function()
      -- Neovim 0.12 ships default `in`/`an` treesitter node-select text objects
      -- (global, x+o modes) that shadow targets.vim's `n`/`l` seek modifier
      -- (e.g. `dinq` = delete inner next quote). They are set after this `init`
      -- runs, so drop them at VimEnter instead of here.
      vim.api.nvim_create_autocmd("VimEnter", {
        desc = "Unmap default in/an node text objects (conflict with targets.vim)",
        callback = function()
          pcall(vim.keymap.del, { "x", "o" }, "in")
          pcall(vim.keymap.del, { "x", "o" }, "an")
        end,
      })
    end,
  },
  { "vim-utils/vim-troll-stopper" }, -- marks "troll" characters
  { "habamax/vim-godot" },
  {
    "zef/vim-cycle",
    init = function()
      vim.g.cycle_override_defaults = {
        { "global", { "true", "false" } },
        { "global", { "<", ">=" } },
        { "global", { ">", "<=" } },
        { "global", { "==", "!=" } },
        { "global", { "===", "!==" } },
        { "global", { "-=", "+=" } },
        { "global", { "&&", "||" } },
        { "vue", { "xs", "sm", "md", "lg", "xl" } },
      }
    end,
  },
}
