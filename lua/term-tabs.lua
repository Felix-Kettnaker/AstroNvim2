-- Terminal tab bar helpers: list/switch/click toggleterm terminals in-place.
-- Used by the winbar component in plugins/custom/heirline.lua and the
-- <C-Tab>/<C-S-Tab> terminal-mode mappings in user/mappings.lua.
local M = {}

-- non-float terminals with live buffers, sorted by id
local function terms()
  return vim.tbl_filter(function(t)
    return t.direction ~= "float" and t.bufnr and vim.api.nvim_buf_is_valid(t.bufnr)
  end, require("toggleterm.terminal").get_all())
end

--- Buffer list source for the heirline winbar buflist
function M.bufs()
  return vim.tbl_map(function(t) return t.bufnr end, terms())
end

-- the non-float terminal hosted in window `win`, if any
local function term_win(win)
  for _, t in ipairs(terms()) do
    if t.window == win then return t end
  end
end

local function show(term, win)
  vim.api.nvim_win_set_buf(win, term.bufnr)
  term.window = win -- keep toggleterm is_open/toggle bookkeeping correct
end

-- shell name tail, e.g. "/bin/zsh;#1" -> "zsh"
local function shell_name(term)
  local name = term.display_name or term.name
  return name and vim.fn.fnamemodify(vim.split(name, ";")[1], ":t") or "term"
end

--- Tab label: the most recently submitted command (cached on the terminal by
--- M.capture / M.set_label), else the shell name. Cached so the label only
--- changes on submit, never while typing.
---@param term table toggleterm Terminal
function M.label(term)
  local s = term.__tab_label or shell_name(term)
  if vim.fn.strcharlen(s) > 22 then s = vim.fn.strcharpart(s, 0, 21) .. "…" end
  return (" 󰆍 %d:%s "):format(term.id, s)
end

--- Cache a command as the current terminal's tab label (used by <leader>fS).
---@param id integer terminal id
---@param cmd string
function M.set_label(id, cmd)
  local term = require("toggleterm.terminal").get(id, true)
  if term then term.__tab_label = cmd end
end

--- Capture the command on the current terminal input line as its tab label.
--- Called on <CR> in toggleterm buffers (see plugins/autocmds.lua). Strips the
--- leading prompt (any run of non-word chars) so it is prompt-agnostic.
function M.capture()
  local term = require("toggleterm.terminal").get(vim.b.toggle_number, true)
  if not term then return end
  local cmd = vim.trim(vim.api.nvim_get_current_line():gsub("^[^%w/~.]*", ""))
  if #cmd > 0 then term.__tab_label = cmd end
end

--- Cycle to the next/previous terminal in the current window (terminal mode)
---@param delta integer 1 = next, -1 = previous
function M.switch(delta)
  local list = terms()
  if #list < 2 then return end
  for i, t in ipairs(list) do
    if t.id == vim.b.toggle_number then
      show(list[(i - 1 + delta) % #list + 1], vim.api.nvim_get_current_win())
      vim.cmd.startinsert() -- invoked from terminal mode, stay in it
      return
    end
  end
end

--- Close the current terminal (like closing a tab): show a sibling in this
--- window first if one exists, then shut the terminal down.
function M.close()
  local list = terms()
  local win = vim.api.nvim_get_current_win()
  local cur = require("toggleterm.terminal").get(vim.b.toggle_number, true)
  if not cur then return end
  local sibling
  for i, t in ipairs(list) do
    if t.id == cur.id then
      sibling = list[i + 1] or list[i - 1]
      break
    end
  end
  if sibling then
    show(sibling, win)
    vim.cmd.startinsert()
  end
  cur:shutdown()
end

--- Keep non-terminal buffers out of the terminal split. If `buf` was placed
--- into a window that hosts a terminal, restore the terminal there and reopen
--- the buffer in an editor window (splitting one off if none exists). Wired to
--- BufWinEnter in plugins/autocmds.lua.
---@param buf integer buffer that just entered a window
function M.keep_terminal(buf)
  if vim.bo[buf].filetype == "toggleterm" then return end
  local win = vim.api.nvim_get_current_win()
  local host = term_win(win)
  if not host or not vim.api.nvim_buf_is_valid(host.bufnr) then return end
  local target
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= win and not term_win(w) and vim.api.nvim_win_get_config(w).relative == "" then
      target = w
      break
    end
  end
  vim.api.nvim_win_set_buf(win, host.bufnr) -- restore terminal in its split
  if target then
    vim.api.nvim_win_set_buf(target, buf)
    vim.api.nvim_set_current_win(target)
  else
    vim.cmd "leftabove split"
    vim.api.nvim_win_set_buf(0, buf)
  end
end

--- Winbar tab click: focus the terminal if visible, else swap it into the
--- clicked window
---@param bufnr integer terminal buffer number (click minwid)
function M.click(bufnr)
  local term = require("toggleterm.terminal").find(function(t) return t.bufnr == bufnr end)
  if not term then return end
  if term:is_open() then return term:focus() end
  local win = vim.fn.getmousepos().winid
  if win ~= 0 and vim.api.nvim_win_is_valid(win) then show(term, win) end
end

return M
