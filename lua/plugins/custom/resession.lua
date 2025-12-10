local function rename_session()
  local dirsession_dir = vim.fn.stdpath "data" .. "/dirsession"

  -- Get list of session files
  local sessions = {}
  for name, type in vim.fs.dir(dirsession_dir) do
    if type == "file" and name:match "%.json$" then table.insert(sessions, (name:gsub("%.json$", ""))) end
  end

  -- Guard
  if #sessions == 0 then
    vim.notify("No sessions found", vim.log.levels.WARN)
    return
  end

  -- get session to rename
  vim.ui.select(sessions, {
    prompt = "Select session to rename:",
  }, function(selected)
    if not selected then
      vim.notify("No session provided", vim.log.levels.WARN)
      return
    end

    -- Prompt for new name
    vim.ui.input({
      prompt = "New session name:",
      default = selected,
    }, function(new_name)
      if not new_name or new_name == "" or new_name == selected then
        vim.notify("No new name provided", vim.log.levels.WARN)
        return
      end

      local old_path = dirsession_dir .. "/" .. selected .. ".json"
      local new_path = dirsession_dir .. "/" .. new_name .. ".json"

      -- Check if new name already exists
      if vim.uv.fs_stat(new_path) then
        vim.notify("Session '" .. new_name .. "' already exists", vim.log.levels.ERROR)
        return
      end

      -- Rename the file
      local success, err = vim.uv.fs_rename(old_path, new_path)
      if success then
        vim.notify("Renamed '" .. selected .. "' to '" .. new_name .. "'")
        if selected == vim.g.current_session_name then vim.g.current_session_name = new_name end
      else
        vim.notify("Failed to rename: " .. err, vim.log.levels.ERROR)
      end
    end)
  end)
end

return {
  "stevearc/resession.nvim",
  lazy = true,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>S"] = false
        maps.n["<Leader>Sl"] = false
        maps.n["<Leader>Ss"] = false
        maps.n["<Leader>SS"] = false
        maps.n["<Leader>St"] = false
        maps.n["<Leader>Sd"] = false
        maps.n["<Leader>SD"] = false
        maps.n["<Leader>Sf"] = false
        maps.n["<Leader>SF"] = false
        maps.n["<Leader>S."] = false

        maps.n["<C-s>"] = { desc = vim.tbl_get(opts, "_map_sections", "<c-s>") }
        maps.n["<C-s>l"] = { function() require("resession").load "Last Session" end, desc = "Load last session" }
        maps.n["<C-s>s"] = { function() require("resession").save() end, desc = "Save this session" }
        maps.n["<C-s><C-s>"] = {
          function() require("resession").save(vim.fn.getcwd():match ".*/(.*)$", { dir = "dirsession" }) end,
          desc = "Save this dirsession",
        }
        maps.n["<C-s>t"] = { function() require("resession").save_tab() end, desc = "Save this tab's session" }
        maps.n["<C-s>d"] = { function() require("resession").delete() end, desc = "Delete a session" }
        maps.n["<C-s><C-d>"] =
          { function() require("resession").delete(nil, { dir = "dirsession" }) end, desc = "Delete a dirsession" }
        maps.n["<C-s><C-r>"] = { rename_session, desc = "Rename a dirsession" }
        maps.n["<C-s>f"] = { function() require("resession").load() end, desc = "Load a session" }
        maps.n["<C-s><C-f>"] =
          { function() require("resession").load(nil, { dir = "dirsession" }) end, desc = "Load a dirsession" }
        maps.n["<C-s>."] = {
          function() require("resession").load(vim.fn.getcwd():match ".*/(.*)$", { dir = "dirsession" }) end,
          desc = "Load current dirsession",
        }

        opts.autocmds.resession_auto_save = {
          {
            event = "VimLeavePre",
            desc = "Save session on close",
            callback = function()
              local buf_utils = require "astrocore.buffer"
              local autosave = require("astrocore").config.sessions.autosave
              if autosave and buf_utils.is_valid_session() then
                local save = require("resession").save
                local session_name = vim.g.current_session_name or vim.fn.getcwd():match ".*/(.*)$"
                if autosave.last then save("Last Session", { notify = false }) end
                if autosave.cwd then save(session_name, { dir = "dirsession", notify = false }) end
              end
            end,
          },
        }
        opts.autocmds.resession_remember_session_name = {
          {
            event = "User",
            pattern = "ResessionLoadPost",
            callback = function() vim.g.current_session_name = require("resession").get_current() end,
          },
        }
      end,
    },
  },
}
