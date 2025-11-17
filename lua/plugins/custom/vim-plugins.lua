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
  { "wellle/targets.vim" },
  { "vim-utils/vim-troll-stopper" }, -- marks "troll" characters
  { "habamax/vim-godot" },
  {
    "zef/vim-cycle",
    init = function()
      vim.g.cycle_override_defaults = {
        { "global", { "true", "false" } },
        { "global", { "<", ">" } },
        { "global", { "==", "!=" } },
        { "global", { "===", "!==" } },
        { "global", { "<=", ">=" } },
        { "global", { "-=", "+=" } },
        { "global", { "&&", "||" } },
      }
    end,
  },
}
