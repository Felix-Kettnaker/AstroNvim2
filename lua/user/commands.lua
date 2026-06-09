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
      require("term-tabs").set_label(new_id, "npm run " .. item.text)
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

--
-- Location Yanker
--
vim.api.nvim_create_user_command("YankLocation", function(opts)
  local path = vim.fn.expand("%:p:.") -- relative path

  local line_info = (opts.line1 == opts.line2)
    and tostring(opts.line1)
    or (opts.line1 .. "-" .. opts.line2)

  local location = path .. ":" .. line_info

  local text = table.concat(
    vim.api.nvim_buf_get_lines(0, opts.line1, opts.line2, false),
    "\n"
  )

  vim.fn.setreg("+", text)
    vim.notify("copied text to clipboard...")
  vim.defer_fn(function()
    vim.fn.setreg("+", location)
    vim.notify("...and location")
  end, 1000)
end, {range = true})


--
-- Sad Project-Wide Search & Replace Picker
-- Step 1: Snacks grep (per-occurrence list, case-sensitive, <M-r> = regex mode)
-- Step 2: sad diff picker — same per-occurrence list, delta preview per hunk.
--
vim.api.nvim_create_user_command("FindAndReplace", function()
  require("snacks").picker.grep({
    title = "Find & Replace",
    -- Start in exact/literal mode; <M-r> toggles to regex mode.
    -- regex = false → grep source adds --fixed-strings; is_exact check below stays consistent.
    regex = false,
    -- Show "R" icon when regex IS active (value=true), not when it's off.
    toggles = { regex = { icon = "R", value = true } },
    -- Override the hardcoded --smart-case in the grep source (last flag wins in rg)
    args = { "--case-sensitive" },
    confirm = function(picker, _item)
      local pattern = picker.input.filter.search
      -- regex == false (the default) means exact/literal mode; true = regex mode
      local is_exact = picker.opts.regex == false
      local match_count = #picker.list.items

      if vim.trim(pattern) == "" then
        vim.notify("sad: empty pattern", vim.log.levels.WARN)
        return
      end

      vim.schedule(function()
        vim.ui.input({ prompt = "replace with" }, function(replacement)
          picker:close()
          if replacement == nil then return end

          local cwd = vim.fn.getcwd()
          -- sad flags: -f I = force case-sensitive (disable smartcase); -e = exact/literal
          local sad_flags = "-f I" .. (is_exact and " -e" or "")
          local rg_flags = "--case-sensitive" .. (is_exact and " --fixed-strings" or "")

          local cmd = "rg -l --null " .. rg_flags .. " "
            .. vim.fn.shellescape(pattern)
            .. " | sad --read0 --fzf never --pager never -u 0 " .. sad_flags .. " "
            .. vim.fn.shellescape(pattern)
            .. " "
            .. vim.fn.shellescape(replacement)

          vim.system({ "sh", "-c", cmd }, { text = true, cwd = cwd }, function(obj)
            local stdout = obj.stdout or ""

            if stdout == "" then
              vim.schedule(function()
                local err = (obj.stderr or ""):gsub("%s+$", "")
                vim.notify(
                  err ~= "" and ("sad: " .. err) or "sad: no matches found",
                  err ~= "" and vim.log.levels.ERROR or vim.log.levels.INFO
                )
              end)
              return
            end

            -- Parse the unified diff into per-file items.
            -- With -u 0, each changed line is its own @@ hunk, so delta still shows
            -- them as separate small blocks even when the full file diff is passed.
            local items = {}
            local current_path = nil
            local current_lines = {}
            local in_file_header = false

            local function save_file()
              if current_path and #current_lines > 0 then
                table.insert(items, {
                  text = current_path,
                  file = current_path,
                  _diff = table.concat(current_lines, "\n"),
                })
              end
            end

            for line in (stdout .. "\n"):gmatch("([^\n]*)\n") do
              if line:match("^diff %-%-git ") then
                save_file()
                current_path, current_lines = nil, { line }
                in_file_header = true
              elseif in_file_header then
                table.insert(current_lines, line)
                if line:match("^--- ") then
                  local abs = line:match("^--- (.+)")
                  if abs then current_path = vim.fn.fnamemodify(abs, ":.") end
                elseif line:match("^%+%+%+ ") then
                  in_file_header = false
                end
              else
                table.insert(current_lines, line)
              end
            end
            save_file()

            if #items == 0 then
              vim.schedule(function()
                vim.notify("sad: no matches found", vim.log.levels.INFO)
              end)
              return
            end

            -- All items are unique files; build list for apply_all.
            local unique_files = vim.tbl_map(function(it) return it.file end, items)

            local function apply_file(path, cb)
              local apply_cmd = "printf '%s\\n' "
                .. vim.fn.shellescape(path)
                .. " | sad --commit " .. sad_flags .. " "
                .. vim.fn.shellescape(pattern)
                .. " "
                .. vim.fn.shellescape(replacement)
              vim.system({ "sh", "-c", apply_cmd }, { text = true, cwd = cwd }, function(res)
                vim.schedule(function()
                  if res.code ~= 0 then
                    vim.notify(
                      "sad error (" .. path .. "): " .. (res.stderr or "unknown"),
                      vim.log.levels.ERROR
                    )
                  else
                    local abs_path = vim.fn.fnamemodify(path, ":p")
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                      if vim.api.nvim_buf_get_name(buf) == abs_path and vim.api.nvim_buf_is_loaded(buf) then
                        vim.api.nvim_buf_call(buf, function() vim.cmd("checktime") end)
                      end
                    end
                  end
                  if cb then cb(res.code == 0) end
                end)
              end)
            end

            vim.schedule(function()
              require("snacks").picker {
                -- title = ("replace %s with %s:  %d match%s"):format(
                title = ("Replace:  %d match%s"):format(
                  -- pattern, replacement,
                  match_count, match_count == 1 and "" or "es"
                ),
                items = items,
                -- Mirror the regex state from the grep picker: show R icon iff regex was active.
                regex = not is_exact,
                toggles = { regex = { icon = "R", value = true } },
                -- Full per-file diff piped to delta; -u 0 keeps each hunk as one changed line.
                preview = function(ctx)
                  require("snacks.picker.preview").cmd({ "delta" }, ctx, { input = ctx.item._diff })
                end,
                format = function(item, _)
                  return { { item.file, "SnacksPickerFile" } }
                end,
                confirm = function(picker2, _item)
                  local targets = picker2:selected({ fallback = true })
                  picker2:close()
                  local n, done = #targets, 0
                  for _, it in ipairs(targets) do
                    apply_file(it.file, function(ok)
                      done = done + 1
                      if n == 1 then
                        if ok then vim.notify("sad: applied → " .. it.file) end
                      elseif done == n then
                        vim.notify(("sad: applied to %d file%s"):format(n, n == 1 and "" or "s"))
                      end
                    end)
                  end
                end,
                win = {
                  input = {
                    keys = { ["<C-a>"] = { "apply_all", mode = { "i", "n" } } },
                  },
                },
                actions = {
                  -- Mode is fixed at this point; disable the toggle to avoid confusion.
                  toggle_regex = function() end,
                  apply_all = function(picker2)
                    picker2:close()
                    local n, done = #unique_files, 0
                    for _, path in ipairs(unique_files) do
                      apply_file(path, function()
                        done = done + 1
                        if done == n then
                          vim.notify(("sad: applied to %d file%s"):format(n, n == 1 and "" or "s"))
                        end
                      end)
                    end
                  end,
                },
              }
            end)
          end)
        end)
      end)
    end,
  })
end, {})

return {}
