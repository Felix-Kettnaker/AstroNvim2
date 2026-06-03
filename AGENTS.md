# Neovim config index

AstroNvim v6+ user config (lazy.nvim). Leader `<Space>`, localleader `,`.
This file maps the layout and says **where to put new things**. Keep it current.

## Load flow

`init.lua`
  → `lua/lazy_setup.lua`  — bootstraps lazy.nvim, imports specs in order:
      `AstroNvim` → `community` → `plugins` → `plugins.custom` → `user`
  → `lua/polish.lua`      — pure-lua, runs **last** (misc tweaks that fit nowhere else)

Lazy spec imports (later overrides earlier). All `plugins/*.lua` and
`plugins/custom/*.lua` are auto-imported LazySpecs.

## Directory map

| Path | Role |
|------|------|
| `init.lua` | entry; don't touch |
| `lua/lazy_setup.lua` | lazy bootstrap + import order + lazy opts |
| `lua/polish.lua` | last-run lua (e.g. `DiagnosticUnnecessary` unlink) |
| `lua/community.lua` | astrocommunity imports (language packs + extras) |
| `lua/jsp.lua` | JSP module: carves buffer into html + java treesitter regions |
| `ftplugin/jsp.lua` | per-JSP-buffer wiring (otter/jdtls, indent, diag filter) |
| `lua/plugins/*.lua` | AstroNvim core module overrides (see below) |
| `lua/plugins/custom/*.lua` | one file per third-party plugin |
| `lua/plugins/custom/vim-plugins.lua` | bundles several vimscript plugins |
| `lua/user/*.lua` | personal mappings, commands, neovide config |
| `after/queries/<lang>/*.scm` | treesitter query overrides/additions |
| `after/lsp/` | per-server LSP overrides |

### Core AstroNvim modules (`lua/plugins/`)
- `astrocore.lua` — options (`vim.opt`/`vim.g`), features, filetypes. **Active.**
- `autocmds.lua` — all autocmds (astrocore `opts.autocmds`). **Active.**
- `astroui.lua` — colorscheme (`catppuccin-mocha`), UI. **Active.**
- `astrolsp.lua` — LSP config. **DISABLED** (`if true then return {}` line 1).
- `mason.lua` — tool/LSP install list. **Active.**
- `treesitter.lua` — **DISABLED**; TS config lives in `astrocore.lua` `opts.treesitter`.
- `none-ls.lua` — **DISABLED**.
- `user.lua` — example plugins. **DISABLED**.

> Several files start with `if true then return {} end` = disabled. Check line 1.

## Where to put stuff

| Want to… | Put it in |
|----------|-----------|
| change a vim option (`opt`/`g`) | `plugins/astrocore.lua` → `opts.options` |
| add an autocmd | `plugins/autocmds.lua` → `opts.autocmds.<group>` |
| add/disable a global keymap | `user/mappings.lua` |
| add a plugin-specific keymap | next to that plugin's spec (e.g. its `plugins/custom/<name>.lua`), not `user/mappings.lua` |
| add a user command | `user/commands.lua` |
| add a third-party plugin | new file in `plugins/custom/<name>.lua` |
| add a vimscript plugin | `plugins/custom/vim-plugins.lua` |
| override an AstroNvim core plugin | matching `plugins/<module>.lua` |
| add an astrocommunity pack | `community.lua` |
| treesitter parser/query | `astrocore.lua` `opts.treesitter` / `after/queries/` |
| LSP server tweak | `after/lsp/<server>.lua`; installs in `mason.lua` |
| one-off lua with no home | `polish.lua` |

## Notable subsystems

- **JSP** (`lua/jsp.lua` + `ftplugin/jsp.lua`): outer html parser, `<% %>`
  scriptlets injected as java via otter→jdtls. Custom indent, diagnostic noise
  filter, otter buffer hardening. Set `vim.g.jsp_servlet_pkg = "jakarta"` for
  Tomcat 10+.
