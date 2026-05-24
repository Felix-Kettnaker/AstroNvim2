-- Carve JSP buffer into html (outside <% %>) and java (inside <% %>) treesitter
-- regions. HTML's native injections handle <script>/<style> -> javascript/css.
local buf = vim.api.nvim_get_current_buf()
require("jsp").attach(buf)

-- Set vim.g.jsp_servlet_pkg = "jakarta" for Tomcat 10+ projects.
local function servlet_pkg() return vim.g.jsp_servlet_pkg == "jakarta" and "jakarta" or "javax" end

local function build_java_preamble()
  local imports = require("jsp").imports(buf)
  local pkg = servlet_pkg()
  local builtins = {
    pkg .. ".servlet.http.HttpServletRequest",
    pkg .. ".servlet.http.HttpServletResponse",
    pkg .. ".servlet.http.HttpSession",
    pkg .. ".servlet.ServletContext",
    pkg .. ".servlet.ServletConfig",
    pkg .. ".servlet.jsp.JspWriter",
    pkg .. ".servlet.jsp.PageContext",
  }
  local parts = { "/* jsp scriptlet wrapper, ftplugin/jsp.lua */" }
  for _, imp in ipairs(builtins) do
    table.insert(parts, "import " .. imp .. ";")
  end
  for _, imp in ipairs(imports) do
    table.insert(parts, "import " .. imp .. ";")
  end
  table.insert(
    parts,
    '@SuppressWarnings("all") class _JspScriptlet { '
      .. "HttpServletRequest request; HttpServletResponse response; HttpSession session; "
      .. "ServletContext application; ServletConfig config; JspWriter out; PageContext pageContext; "
      .. "Object page; Throwable exception; "
      .. "void _jspService() throws Throwable {"
  )
  return { table.concat(parts, " ") }
end

-- Merge chunks in the otter buffer when multiple chunks land on the same line.
-- Otter writes `ls[start_row + i] = line`, so two chunks that end/start on the
-- same row (e.g. `<%if (x) {%>...<%}%>` on one line, or a multi-line scriptlet
-- whose closing `%>` shares the row with the next `<%`) clobber each other.
-- Lost chunks break brace pairing (`} else if` looking unmatched, etc).
--
-- Build a row -> list-of-pieces map by replaying otter's writer logic, then
-- rewrite each shared row with the pieces concatenated.
local function fixup_same_line_chunks(main_nr)
  local ok, keeper = pcall(require, "otter.keeper")
  if not ok then return end
  local raft = keeper.rafts[main_nr]
  if not raft then return end
  for _, lang in ipairs { "java", "java_expr" } do
    local otter_nr = raft.buffers[lang]
    local chunks = raft.code_chunks and raft.code_chunks[lang]
    if otter_nr and chunks and vim.api.nvim_buf_is_valid(otter_nr) then
      local row_pieces = {}
      for _, c in ipairs(chunks) do
        local start_row = c.range.from[1]
        for i, line in ipairs(c.text) do
          local otter_row = start_row + i -- 1-indexed otter line
          row_pieces[otter_row] = row_pieces[otter_row] or {}
          table.insert(row_pieces[otter_row], line)
        end
      end
      for otter_row, pieces in pairs(row_pieces) do
        if #pieces > 1 then
          local merged = table.concat(pieces, " ")
          pcall(vim.api.nvim_buf_set_lines, otter_nr, otter_row - 1, otter_row, false, { merged })
        end
      end
    end
  end
end

-- Otter's `leading_offset` is derived from how many spaces the chunk text
-- begins with. For markdown/quarto that's the right thing — code blocks live
-- at column 0 with their bodies indented. JSP scriptlets begin mid-line
-- (after `<%`), so we instead set leading_offset to the chunk's source
-- start_col. That makes otter's position translation send the right column
-- to jdtls (and translate responses back), so gd / references resolve.
local function fixup_leading_offsets(main_nr)
  local ok, keeper = pcall(require, "otter.keeper")
  if not ok then return end
  local raft = keeper.rafts[main_nr]
  if not raft or not raft.code_chunks then return end
  for _, lang in ipairs { "java", "java_expr" } do
    for _, c in ipairs(raft.code_chunks[lang] or {}) do
      c.leading_offset = c.range.from[2]
    end
  end
end

local function patch_otter_once()
  if vim.g._jsp_otter_patched then return end
  vim.g._jsp_otter_patched = true
  local ok, keeper = pcall(require, "otter.keeper")
  if not ok then return end
  local orig = keeper.sync_raft
  keeper.sync_raft = function(main_nr, language)
    local r = orig(main_nr, language)
    if require("jsp").is_attached(main_nr) then
      fixup_leading_offsets(main_nr)
      fixup_same_line_chunks(main_nr)
    end
    return r
  end
end

-- Hide *.otter.* virtual buffers from :ls and buffer pickers. We do write
-- otter files to disk now (jdtls needs them there for semantic analysis on
-- local variables), but they live in stdpath("cache")/jsp-otter, away from
-- the project. Also clean up any stale otter files left next to the .jsp
-- itself from earlier sessions (before we redirected paths to the cache).
local function harden_otter_buffers(main_nr)
  local ok, keeper = pcall(require, "otter.keeper")
  if not ok then return end
  local raft = keeper.rafts[main_nr]
  if not raft then return end
  for _, otter_nr in pairs(raft.buffers) do
    if vim.api.nvim_buf_is_valid(otter_nr) then vim.bo[otter_nr].buflisted = false end
  end
  local main_path = vim.api.nvim_buf_get_name(main_nr)
  if main_path == "" then return end
  for _, ext in ipairs { "java", "css", "js" } do
    local stale = main_path .. ".otter." .. ext
    if vim.fn.filereadable(stale) == 1 then pcall(vim.fn.delete, stale) end
  end
end

-- jsp-aware indent: html lines go through vim's HtmlIndent() (lenient with
-- JSP custom tags like <batix:headline>); java scriptlet lines go through
-- nvim-treesitter's indent on the java tree.
--
-- nvim-treesitter's stock indent picks the smallest tree by byte_length and
-- our java tree's outer range spans the whole file via gappy regions, which
-- fools the size compare and yields 0 indent for deeply nested html.
vim.cmd "runtime! indent/html.vim"
local function jsp_indentexpr()
  if vim.bo.filetype ~= "jsp" then return -1 end
  local lnum = vim.v.lnum
  local row = lnum - 1
  if require("jsp").row_has_java(0, row) then
    local indent = require "nvim-treesitter.indent"
    local saved = indent.comment_parsers.html
    indent.comment_parsers.html = true
    local result = indent.get_indent(lnum)
    indent.comment_parsers.html = saved
    return result
  end
  if vim.fn.exists "*HtmlIndent" == 1 then return vim.fn.HtmlIndent() end
  return -1
end
_G._jsp_indentexpr = jsp_indentexpr

-- jdtls runs the jsp otter file in a standalone workspace, so user types like
-- `Tools`, `PluginsManager` etc. aren't on its classpath and get flagged
-- "cannot be resolved". Those aren't real code bugs from the user's
-- perspective, so suppress them. Real syntax errors (unbalanced braces,
-- missing semicolons) still come through.
local NOISE_PATTERNS = {
  "cannot be resolved",
  "is not on the classpath",
  "must implement the inherited abstract method",
}
local function is_noise(msg)
  msg = msg:lower()
  for _, p in ipairs(NOISE_PATTERNS) do
    if msg:find(p:lower(), 1, true) then return true end
  end
  return false
end

local function install_diag_filter(main_nr)
  local group = vim.api.nvim_create_augroup("JspDiagFilter" .. main_nr, { clear = true })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    buffer = main_nr,
    callback = function()
      for ns_name, ns_id in pairs(vim.api.nvim_get_namespaces()) do
        if ns_name:match "^otter%-lang%-" then
          local diags = vim.diagnostic.get(main_nr, { namespace = ns_id })
          local kept, dropped = {}, false
          for _, d in ipairs(diags) do
            if is_noise(d.message) then
              dropped = true
            else
              table.insert(kept, d)
            end
          end
          if dropped then vim.diagnostic.set(ns_id, main_nr, kept) end
        end
      end
    end,
  })
end

vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(buf) then return end
  -- jsp.vim's runtime ftplugin sources html.vim then java.vim, which last
  -- writes indentexpr. Set our custom expr after those handlers ran.
  vim.bo[buf].indentexpr = "v:lua._jsp_indentexpr()"

  -- nvim-jdtls is `ft = { "java" }` lazy-loaded. If otter is the first thing
  -- to set ft=java on a buffer, the FileType=java event fires BEFORE jdtls's
  -- own autocmd is registered, so jdtls never attaches. Force-load the
  -- plugin so its autocmd is ready before otter activates.
  pcall(require("lazy").load, { plugins = { "nvim-jdtls" } })

  local ok, otter = pcall(require, "otter")
  if not ok then return end
  patch_otter_once()
  otter.activate({ "java", "html", "css", "javascript" }, true, true, nil, {
    java = build_java_preamble(),
  }, {
    java = { "}}" },
  })
  harden_otter_buffers(buf)
  fixup_leading_offsets(buf)
  fixup_same_line_chunks(buf)
  install_diag_filter(buf)
end)
