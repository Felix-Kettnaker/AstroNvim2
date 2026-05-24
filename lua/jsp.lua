-- JSP language injection.
--
-- The file's outer language is HTML. <% %>-style scriptlets are split off and
-- handed to the java parser as a separate injection region. HTML's bundled
-- injections.scm still handles <style>/<script> -> css/javascript on the
-- carved-up HTML content.
--
-- Comments and directives sit outside both region sets and get extmark-based
-- highlights instead.

local M = {}

local ns = vim.api.nvim_create_namespace "jsp_injection"

local DELIM_HL = "@tag.delimiter"
local COMMENT_HL = "@comment"
local DIRECTIVE_NAME_HL = "@keyword.directive"
local DIRECTIVE_ATTR_HL = "@tag.attribute"
local DIRECTIVE_VALUE_HL = "@string"

local function compute_ranges(text)
  local html_ranges = {}
  local java_ranges = {} -- <% scriptlet %> and <%! decl %> bodies (LSP via otter)
  local java_expr_ranges = {} -- <%= expr %> bodies (treesitter only; jdtls would
  -- flag a bare expression as an invalid statement)
  -- Each marker: { start_byte, end_byte, hl_group }
  local marks = {}
  -- Imports collected from <%@page import="a.b.C, d.e.*" %>
  local imports = {}

  local pos = 1
  local last_pos = 1

  while true do
    local s = text:find("<%", pos, true)
    if not s then break end

    if s > last_pos then table.insert(html_ranges, { last_pos - 1, s - 1 }) end

    local prefix3 = text:sub(s, s + 2)
    local prefix4 = text:sub(s, s + 3)
    local block_end_idx
    local java_s, java_e

    if prefix4 == "<%--" then
      local _, ce = text:find("--%>", s + 4, true)
      if not ce then break end
      block_end_idx = ce
      table.insert(marks, { s - 1, ce, COMMENT_HL })
    elseif prefix3 == "<%@" then
      local _, ce = text:find("%>", s + 3, true)
      if not ce then break end
      block_end_idx = ce
      table.insert(marks, { s - 1, s + 2, DELIM_HL })
      table.insert(marks, { ce - 2, ce, DELIM_HL })
      local body_s = s + 3
      local ms, me = text:find("%w+", body_s)
      local directive_name
      if ms and me < ce - 1 then
        directive_name = text:sub(ms, me)
        table.insert(marks, { ms - 1, me, DIRECTIVE_NAME_HL })
        local cursor = me + 1
        while cursor < ce - 1 do
          local ks, ke = text:find("%w[%w_-]*%s*=", cursor)
          if not ks or ks >= ce - 1 then break end
          local _, eq = text:find("=", ks, true)
          local key_end = eq - 1
          while text:sub(key_end, key_end):match "%s" do
            key_end = key_end - 1
          end
          local key_name = text:sub(ks, key_end)
          table.insert(marks, { ks - 1, key_end, DIRECTIVE_ATTR_HL })
          local vs = eq + 1
          while text:sub(vs, vs):match "%s" do
            vs = vs + 1
          end
          local q = text:sub(vs, vs)
          if q == '"' or q == "'" then
            local ve = text:find(q, vs + 1, true)
            if ve and ve < ce then
              table.insert(marks, { vs - 1, ve, DIRECTIVE_VALUE_HL })
              if directive_name == "page" and key_name == "import" then
                local value = text:sub(vs + 1, ve - 1)
                for token in value:gmatch "[^,]+" do
                  local trimmed = token:match "^%s*(.-)%s*$"
                  if trimmed and #trimmed > 0 then table.insert(imports, trimmed) end
                end
              end
              cursor = ve + 1
            else
              break
            end
          else
            cursor = eq + 1
          end
        end
      end
    elseif prefix3 == "<%!" then
      local _, ce = text:find("%>", s + 3, true)
      if not ce then break end
      block_end_idx = ce
      table.insert(marks, { s - 1, s + 2, DELIM_HL })
      table.insert(marks, { ce - 2, ce, DELIM_HL })
      java_s, java_e = s + 3, ce - 2
    elseif prefix3 == "<%=" then
      local _, ce = text:find("%>", s + 3, true)
      if not ce then break end
      block_end_idx = ce
      table.insert(marks, { s - 1, s + 2, DELIM_HL })
      table.insert(marks, { ce - 2, ce, DELIM_HL })
      local es, ee = s + 3, ce - 2
      if ee >= es then table.insert(java_expr_ranges, { es - 1, ee }) end
    else
      local _, ce = text:find("%>", s + 2, true)
      if not ce then break end
      block_end_idx = ce
      table.insert(marks, { s - 1, s + 1, DELIM_HL })
      table.insert(marks, { ce - 2, ce, DELIM_HL })
      java_s, java_e = s + 2, ce - 2
    end

    if java_s and java_e >= java_s then table.insert(java_ranges, { java_s - 1, java_e }) end

    last_pos = block_end_idx + 1
    pos = last_pos
  end

  if last_pos <= #text then table.insert(html_ranges, { last_pos - 1, #text }) end

  return html_ranges, java_ranges, java_expr_ranges, marks, imports
end

local function build_line_offsets(buf)
  local n = vim.api.nvim_buf_line_count(buf)
  local off = {}
  for i = 0, n do
    off[i] = vim.api.nvim_buf_get_offset(buf, i)
  end
  return off, n
end

local function byte_to_pos(offsets, n, byte)
  local lo, hi = 0, n
  while lo + 1 < hi do
    local mid = math.floor((lo + hi) / 2)
    if offsets[mid] <= byte then
      lo = mid
    else
      hi = mid
    end
  end
  return lo, byte - offsets[lo]
end

local function ranges_to_region(byte_ranges, offsets, n)
  local region = {}
  for _, r in ipairs(byte_ranges) do
    local sb, eb = r[1], r[2]
    if eb > sb then
      local sr, sc = byte_to_pos(offsets, n, sb)
      local er, ec = byte_to_pos(offsets, n, eb)
      table.insert(region, { sr, sc, sb, er, ec, eb })
    end
  end
  return region
end

local function apply_marks(buf, marks, offsets, n)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local sb, eb, hl = m[1], m[2], m[3]
    local sr, sc = byte_to_pos(offsets, n, sb)
    local er, ec = byte_to_pos(offsets, n, eb)
    vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, {
      end_row = er,
      end_col = ec,
      hl_group = hl,
      priority = 110,
    })
  end
end

local attached = {}
local imports_by_buf = {}
local java_rows_by_buf = {} -- set of rows that contain java content (scriptlet/decl/expr)

function M.imports(buf) return imports_by_buf[buf or vim.api.nvim_get_current_buf()] or {} end

function M.is_attached(buf) return attached[buf or vim.api.nvim_get_current_buf()] == true end

function M.row_has_java(buf, row)
  local rows = java_rows_by_buf[buf or vim.api.nvim_get_current_buf()]
  return rows and rows[row] == true
end

-- Set up `java_expr`: an alias of the java parser so <%= expr %> bodies get
-- treesitter highlighting without otter routing them to jdtls (which would
-- flag a bare expression as an invalid statement).
local expr_lang_ready = false
local function ensure_java_expr_lang()
  if expr_lang_ready then return end
  expr_lang_ready = true
  local paths = vim.api.nvim_get_runtime_file("parser/java.*", false)
  if #paths == 0 then return end
  local ok = pcall(vim.treesitter.language.add, "java_expr", { path = paths[1], symbol_name = "java" })
  if not ok then return end
  if vim.treesitter.query.get("java_expr", "highlights") then return end
  for _, q in ipairs { "highlights", "injections", "locals" } do
    local files = vim.treesitter.query.get_files("java", q)
    local text = ""
    for _, f in ipairs(files) do
      local h = io.open(f, "r")
      if h then
        text = text .. h:read "*a" .. "\n"
        h:close()
      end
    end
    if #text > 0 then vim.treesitter.query.set("java_expr", q, text) end
  end
end

local state = {} -- per-buf: { html_lt, refresh, cached_java, cached_java_expr }

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local s = state[buf]
  if s and s.refresh then s.refresh() end
end

function M.attach(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  ensure_java_expr_lang()
  vim.treesitter.language.register("html", "jsp")
  local ok, html_lt = pcall(vim.treesitter.get_parser, buf, "html")
  if not ok or not html_lt then return end

  -- If we already attached to this buf with the same parser instance, just
  -- run a refresh (handles `:e!` reload, which keeps the buffer alive).
  if attached[buf] and state[buf] and state[buf].html_lt == html_lt then
    state[buf].refresh()
    return
  end

  attached[buf] = true

  local cached_java = {}
  local cached_java_expr = {}

  -- Drop CSS/JS injections that come from html attribute values
  -- (style="..." and on*="..."). Their content is fragment-level (no enclosing
  -- selector / function), which makes cssls and vtsls emit spurious errors.
  -- Treesitter highlight on those attributes still works via html's own rules.
  local function drop_attribute_injections(self, injections)
    local tree = self:trees()[1]
    if not tree then return end
    local root = tree:root()
    for _, lang in ipairs { "css", "javascript" } do
      local regions = injections[lang]
      if regions then
        local kept = {}
        for _, region in ipairs(regions) do
          local from_attr = false
          local first = region[1]
          if first then
            local sr, sc, _, er, ec = first[1], first[2], first[3], first[4], first[5]
            local n = root:descendant_for_range(sr, sc, er, ec)
            while n do
              local t = n:type()
              if t == "attribute_value" or t == "quoted_attribute_value" or t == "attribute" then
                from_attr = true
                break
              end
              if t == "raw_text" or t == "style_element" or t == "script_element" then break end
              n = n:parent()
            end
          end
          if not from_attr then table.insert(kept, region) end
        end
        injections[lang] = #kept > 0 and kept or nil
      end
    end
  end

  local orig_get_injections = html_lt._get_injections
  html_lt._get_injections = function(self, range, thread_state)
    local injections, t = orig_get_injections(self, range, thread_state)
    drop_attribute_injections(self, injections)
    if #cached_java > 0 then injections.java = { cached_java } end
    if #cached_java_expr > 0 then injections.java_expr = { cached_java_expr } end
    return injections, t
  end

  local function refresh()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    local html_ranges, java_ranges, java_expr_ranges, marks, imports = compute_ranges(text)
    imports_by_buf[buf] = imports
    local offsets, n = build_line_offsets(buf)
    local html_region = ranges_to_region(html_ranges, offsets, n)
    cached_java = ranges_to_region(java_ranges, offsets, n)
    cached_java_expr = ranges_to_region(java_expr_ranges, offsets, n)

    local rows = {}
    for _, r in ipairs(cached_java) do
      for i = r[1], r[4] do
        rows[i] = true
      end
    end
    for _, r in ipairs(cached_java_expr) do
      for i = r[1], r[4] do
        rows[i] = true
      end
    end
    java_rows_by_buf[buf] = rows

    if #html_region > 0 then html_lt:set_included_regions { html_region } end
    html_lt:invalidate(true)
    html_lt:parse(true)
    apply_marks(buf, marks, offsets, n)
  end

  refresh()
  pcall(vim.treesitter.stop, buf) -- in case a stale highlighter is attached
  vim.treesitter.start(buf, "html")

  state[buf] = { html_lt = html_lt, refresh = refresh }

  -- Autocmds (instead of nvim_buf_attach) so refresh survives :e/:e! reloads,
  -- which detach buf_attach callbacks but keep the buffer alive.
  local group = vim.api.nvim_create_augroup("JspRefresh." .. buf, { clear = true })
  local debounce
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufReadPost" }, {
    group = group,
    buffer = buf,
    callback = function()
      if debounce then return end
      debounce = true
      vim.schedule(function()
        debounce = false
        if vim.api.nvim_buf_is_valid(buf) then refresh() end
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = group,
    buffer = buf,
    callback = function()
      attached[buf] = nil
      imports_by_buf[buf] = nil
      java_rows_by_buf[buf] = nil
      state[buf] = nil
      pcall(vim.api.nvim_del_augroup_by_id, group)
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
    end,
  })
end

return M
