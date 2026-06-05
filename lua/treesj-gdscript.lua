-- treesj language config for GDScript (tree-sitter-gdscript).
--
-- Staged here as `treeSJ.gdscript.lua`; the body is a drop-in treesj lang file
-- (same shape as lua/treesj/langs/*.lua) so it can be moved to
-- `lua/treesj/langs/gdscript.lua` in a fork and registered in langs/init.lua.
--
-- Handles:
--   * bracketed nodes: argument/parameter lists, arrays, dictionaries, enum
--     bodies, plus redirects from the statements/expressions that contain a
--     list/dict literal. NOTE: `call`/`attribute_call` are deliberately NOT
--     redirected to their `arguments` — splitting a call's args should only
--     happen with the cursor inside its `()` (the `arguments` self preset),
--     not from the call name, so that toggling a bare call statement targets
--     the enclosing block instead.
--   * statement bodies (if/elif/else/for/while/match/func): the `:`-introduced
--     indented block, toggled inline <-> multiline.
--
-- Why `body` uses `fallback` instead of `set_preset_for_non_bracket`:
-- treesj's non_bracket range model frames a node with `prev_sibling`/
-- `next_sibling` (e.g. lua's `then ... end`). GDScript blocks have no closing
-- token, so for a body followed by another statement treesj extends the join
-- range to `node:parent():next_sibling()` and swallows that statement. We take
-- over via the documented `fallback` preset field and edit the text directly
-- (correct ranges, single-statement-only join, no `;`-joining).
-- (For an upstream PR this would ideally be a core fix for delimiter-less
-- non_bracket nodes rather than a per-lang fallback.)
local lang_utils = require('treesj.langs.utils')

-- GDScript style: no spaces just inside [], {} (e.g. `[1, 2]`, `{"a": 1}`).
local no_space_in_brackets_list = lang_utils.set_preset_for_list({
  join = { space_in_brackets = false },
})
local no_space_in_brackets_dict = lang_utils.set_preset_for_dict({
  join = { space_in_brackets = false },
})

-- Toggle a `:`-introduced indented block inline <-> multiline.
-- Honors treesj's `cursor_behavior` setting ('hold' | 'start' | 'end').
local function toggle_body(node)
  local bufnr = vim.api.nvim_get_current_buf()
  local behavior = require('treesj.settings').settings.cursor_behavior
  local cur = vim.api.nvim_win_get_cursor(0) -- { row(1-based), col(0-based) }

  local bsr, bsc, ber, bec = node:range()
  local stmts = {}
  for c in node:iter_children() do
    if c:named() then stmts[#stmts + 1] = c end
  end
  if #stmts == 0 then return end

  -- Anchor the edit at the end of the `:` (body's prev sibling) so the space
  -- between `:` and the body is consumed (no trailing space left behind).
  local sr, sc = bsr, bsc
  local prev = node:prev_sibling()
  if prev then
    local _, _, per, pec = prev:range()
    sr, sc = per, pec
  end

  local indent = vim.api.nvim_buf_get_lines(bufnr, sr, sr + 1, true)[1]:match('^%s*')
  local unit = vim.bo[bufnr].expandtab and string.rep(' ', vim.fn.shiftwidth()) or '\t'
  local prefix = indent .. unit
  local new_cursor

  if bsr == ber then
    -- inline -> multiline: each statement on its own, deeper-indented line
    local lines = { '' }
    local stmt_cols = {} -- original start col of each statement on the inline line
    for i, s in ipairs(stmts) do
      local _, ssc = s:range()
      stmt_cols[i] = ssc
      lines[i + 1] = prefix .. vim.treesitter.get_node_text(s, bufnr)
    end

    if behavior == 'start' then
      new_cursor = { sr + 2, #prefix }
    elseif behavior == 'end' then
      new_cursor = { sr + #lines, #lines[#lines] }
    elseif cur[1] - 1 == bsr then -- hold, cursor on the inline line
      -- find the statement the cursor sits in (or before)
      local idx
      for i = #stmts, 1, -1 do
        if cur[2] >= stmt_cols[i] then idx = i; break end
      end
      if idx then new_cursor = { sr + 1 + idx, #prefix + (cur[2] - stmt_cols[idx]) } end
    end

    vim.api.nvim_buf_set_text(bufnr, sr, sc, ber, bec, lines)
  else
    -- multiline -> inline: single, single-line statement only (never join with `;`)
    if #stmts ~= 1 then
      require('treesj.notify').warn('GDScript: cannot join a multi-statement block to one line')
      return
    end
    local s = stmts[1]
    local ssr, ssc, ser = s:range()
    if ssr ~= ser then
      require('treesj.notify').warn('GDScript: cannot join a body whose statement spans multiple lines')
      return
    end
    local text = vim.treesitter.get_node_text(s, bufnr)
    -- the statement lands at column sc + 1 (after the single inserted space)
    if behavior == 'start' then
      new_cursor = { sr + 1, sc + 1 }
    elseif behavior == 'end' then
      new_cursor = { sr + 1, sc + 1 + #text }
    elseif cur[1] - 1 == ssr and cur[2] >= ssc then -- hold, cursor in the statement
      new_cursor = { sr + 1, sc + 1 + (cur[2] - ssc) }
    end

    vim.api.nvim_buf_set_text(bufnr, sr, sc, ber, bec, { ' ' .. text })
  end

  if new_cursor then pcall(vim.api.nvim_win_set_cursor, 0, new_cursor) end
end

return {
  -- bracketed nodes (self presets)
  arguments = lang_utils.set_preset_for_args(),
  parameters = lang_utils.set_preset_for_args(),
  array = no_space_in_brackets_list,
  dictionary = no_space_in_brackets_dict,
  enumerator_list = no_space_in_brackets_dict,

  -- statement body (the `:`-introduced indented block), handled via fallback
  body = lang_utils.set_default_preset({ both = { fallback = toggle_body } }),

  -- redirects: jump from the containing node to its bracketed child
  lambda = { target_nodes = { 'parameters' } },
  enum_definition = { target_nodes = { 'enumerator_list' } },

  -- redirects: jump from a block owner to its body (params via cursor inside ())
  function_definition = { target_nodes = { 'body' } },
  if_statement = { target_nodes = { 'body' } },
  elif_clause = { target_nodes = { 'body' } },
  else_clause = { target_nodes = { 'body' } },
  for_statement = { target_nodes = { 'body' } },
  while_statement = { target_nodes = { 'body' } },
  pattern_section = { target_nodes = { 'body' } },

  -- statements whose right-hand side may be a list/dict literal
  assignment = { target_nodes = { 'array', 'dictionary' } },
  augmented_assignment = { target_nodes = { 'array', 'dictionary' } },
  variable_statement = { target_nodes = { 'array', 'dictionary' } },
  const_statement = { target_nodes = { 'array', 'dictionary' } },
  return_statement = { target_nodes = { 'array', 'dictionary' } },
}
