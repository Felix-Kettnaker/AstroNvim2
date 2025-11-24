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

return {}
