-- Split line at delimiter
vim.api.nvim_create_user_command("SplitLineAt", function(opts)
  local function splitLineAt(delimiter)
    -- strip quotes
    local _, body = delimiter:match [[^(['"])(.*)%1$]]
    delimiter = body or delimiter

    -- Get cursor position and line
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

    -- Split by the delimiter (plain match)
    local parts = {}
    if delimiter == " " then
      for part in string.gmatch(line, "([^" .. delimiter .. "]+)") do
        table.insert(parts, part)
      end
    else
      -- keep the delimiter without trailing spaces (e.g. ", " -> ",")
      local prefix = delimiter:gsub("%s+$", "")
      local keep = #prefix
      local i = 1

      while true do
        local s, e = string.find(line, delimiter, i, true) -- plain search
        if not s then
          table.insert(parts, string.sub(line, i))
          break
        end

        -- include the prefix part of the delimiter at the end of the left piece
        local cut_end = (keep > 0) and (s + keep - 1) or (s - 1)
        table.insert(parts, string.sub(line, i, cut_end))

        -- continue after the whole delimiter (drop trailing spaces)
        i = e + 1
      end
    end

    -- Replace the line with the split result
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, parts)

    -- Reindent the inserted range
    vim.cmd("norm! " .. #parts .. "=j")
  end

  if not opts.args or opts.args == "" then
    vim.ui.input({ prompt = "Enter Split Delimiter:" }, function(input)
      if not input or input == "" then
        vim.notify("No input provided", vim.log.levels.WARN)
        return
      end
      splitLineAt(input)
    end)
  else
    splitLineAt(opts.args)
  end
end, {})

--
-- NPM Scripts Picker
--
vim.api.nvim_create_user_command("PickNpmScript", function(_opts)
  local path = vim.fn.findfile("package.json", ".;")
  if path == "" then return vim.notify("No package.json found", vim.log.levels.WARN) end

  -- 1. Decode JSON to get the commands safely
  local content = table.concat(vim.fn.readfile(path), "\n")
  local ok, json = pcall(vim.fn.json_decode, content)
  if not ok or not json.scripts then return vim.notify("No scripts found in package.json", vim.log.levels.WARN) end

  -- 2. Scan file manually to get keys in definition order
  -- (Lua tables are unordered, so pairs(json.scripts) destroys file order)
  local script_keys = {}
  local in_scripts = false
  local line_num = 0
  for line in io.lines(path) do
    line_num = line_num + 1
    if not in_scripts then
      -- Look for "scripts": {
      if line:match '^%s*"scripts"%s*:%s*{' then in_scripts = true end
    else
      -- Stop if we hit the closing brace of scripts
      if line:match "^%s*}" then break end

      -- Extract key from line: "start": "..."
      local key = line:match '^%s*"(.-)"%s*:'
      if key and json.scripts[key] then table.insert(script_keys, { name = key, line = line_num }) end
    end
  end

  -- Fallback: If regex failed (e.g. minified JSON), use random pairs order
  local do_file_preview = #script_keys > 0
  if not do_file_preview then
    for k, _ in pairs(json.scripts) do
      table.insert(script_keys, k)
    end
    table.sort(script_keys) -- At least sort A-Z if we can't get file order
  end

  -- 3. Build items list based on the ordered keys
  local items = {}
  for _, key in ipairs(script_keys) do
    local cmd_name = key.name or key
    table.insert(items, {
      text = cmd_name,
      file = path,
      pos = do_file_preview and { key.line, 1 } or nil,
      preview = do_file_preview and nil or {
        text = json.scripts[cmd_name],
        ft = "sh", -- syntax highlighting
      },
    })
  end

  -- 4. Open Picker
  require("snacks").picker {
    title = "NPM Scripts",
    items = items,
    -- enable line wrap in preview window
    on_show = function(picker) picker.preview.win.opts.wo.wrap = true end,
    preview = do_file_preview and "file" or "preview",
    format = function(item, _)
      return {
        { item.text, "SnacksPickerLabel" },
        { " " },
        { item.cmd, "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      -- Determine new terminal ID
      local terminals = require("toggleterm.terminal").get_all()
      local new_id = (#terminals > 0) and (terminals[#terminals].id + 1) or 1
      -- Run in ToggleTerm
      vim.cmd(new_id .. "TermExec cmd='npm run " .. item.text .. "' size=10 direction=horizontal")
    end,
  }
end, {})

--
-- Toggleterm Picker
--
vim.api.nvim_create_user_command("PickTerminal", function(opts)
  local terminals = require("toggleterm.terminal").get_all(opts.bang)
  if #terminals == 0 then return require("toggleterm.utils").notify("No toggleterms are open yet", "info") end

  local items = {}

  for _, term in ipairs(terminals) do
    local lines = ""
    local command = term.cmd or ""
    if vim.api.nvim_buf_is_valid(term.bufnr) then
      -- Get all lines (0 to -1)
      local lines_map = vim.api.nvim_buf_get_lines(term.bufnr, 0, -1, false)
      lines = table.concat(lines_map, "\n")
      -- if 2. line starts with $, command is in 1. line, else in 2. line
      if lines_map[2]:match "^%s*%$" then
        command = lines_map[1]
      else
        command = lines_map[2]
      end
    end
    table.insert(items, {
      title = "Terminals",
      -- text = string.format("%d [%s]: %s", term.id, term:_display_name(), command),
      t_id = term.id,
      t_name = string.format(" [%s]: ", term:_display_name()),
      t_command = command,
      term = term,
      -- last line
      pos = { vim.api.nvim_buf_line_count(term.bufnr), 1 },
      preview = {
        text = lines,
      },
    })
  end

  require("snacks").picker.pick {
    title = "Select Terminal",
    items = items,
    -- format = "text",
    format = function(item, _)
      return {
        { tostring(item.t_id), "SnacksPickerLabel" },
        { item.t_name, "Comment" },
        { item.t_command, "sh" },
      }
    end,
    preview = "preview",
    confirm = function(picker, item)
      picker:close()
      if item then
        local term = item.term
        if term:is_open() then
          term:focus()
        else
          term:open()
        end
      end
    end,
  }
end, {})

return {}
