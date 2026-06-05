return {
  "Wansmer/treesj",
  opts = function(_, opts)
    opts.use_default_keymaps = false
    opts.max_join_length = 160

    local utils = require('treesj.langs.utils')
    local ternary = utils.set_preset_for_non_bracket({
      both = {
        omit = {
          function(tsj)
            local prev = tsj:tsnode():prev_sibling()
            -- first child (condition) -> stay on the opening line
            if prev == nil then return true end
            -- consequence / alternative -> stay attached to ? or :
            local t = prev:type()
            return t == '?' or t == ':'
          end,
        },
      },
      split = {
        last_indent = 'inner',
      },
    })

    -- strip the braces of a single-statement block (force inline, no `;`)
    local function strip_braces(tsj)
      tsj:remove_child({ '{', '}' })
      tsj:update_preset({ force_insert = '', space_in_brackets = false }, 'join')
    end

    -- Brace toggle for braceless `if` consequences, which the default
    -- if_statement preset can't do (it only redirects to an existing
    -- statement_block). We redirect the `consequence` field to this preset;
    -- modeled on the built-in arrow `body` preset, it wraps/unwraps the braces.
    -- Handles the cursor-on-`if` entry point.
    local if_body = utils.set_preset_for_statement({
      split = {
        format_tree = function(tsj)
          if tsj:type() ~= 'statement_block' then tsj:wrap({ left = '{', right = '}' }) end
        end,
      },
      join = {
        format_tree = function(tsj)
          if tsj:type() == 'statement_block' and tsj:tsnode():named_child_count() == 1 then
            strip_braces(tsj)
          end
        end,
      },
    })

    -- Replicates the built-in javascript arrow `body` join (unwrap `{}` + drop
    -- `return`) so overriding statement_block below doesn't break arrows.
    local rec_ignore = { 'arguments', 'formal_parameters' }
    local function arrow_body_format_join(tsj)
      if tsj:tsnode():parent():type() == 'arrow_function' and tsj:tsnode():named_child_count() == 1 then
        strip_braces(tsj)
        local stmt = tsj:child('return_statement') or tsj:child('expression_statement')
        if stmt then
          if stmt:has_to_format() then
            stmt:remove_child({ 'return', ';' })
            if stmt:child('object') then tsj:wrap({ left = '(', right = ')' }, 'inline') end
          else
            stmt:update_text((stmt:text():gsub('^return ', ''):gsub(';$', '')))
          end
        end
      end
    end

    -- Override statement_block so a single-statement `if` body also unwraps when
    -- the cursor is *inside* the block (treesj selects the block directly then,
    -- not the if_statement). Keeps braces for multi-statement blocks.
    local statement_block = utils.set_preset_for_statement({
      split = { recursive_ignore = rec_ignore },
      join = {
        no_insert_if = { 'function_declaration', 'try_statement', 'if_statement' },
        format_tree = function(tsj)
          local parent = tsj:tsnode():parent()
          if parent and parent:type() == 'if_statement' and tsj:tsnode():named_child_count() == 1 then
            strip_braces(tsj)
          else
            arrow_body_format_join(tsj)
          end
        end,
      },
    })

    local if_statement = { target_nodes = { consequence = 'if_body' } }
    local langs = {
      ternary_expression = ternary,
      if_statement = if_statement,
      if_body = if_body,
      statement_block = statement_block,
    }

    -- Java: same idea, but its block node is `block` (not `statement_block`)
    -- and there is no arrow body to preserve.
    local java_if_body = utils.set_preset_for_statement({
      split = {
        format_tree = function(tsj)
          if tsj:type() ~= 'block' then tsj:wrap({ left = '{', right = '}' }) end
        end,
      },
      join = {
        format_tree = function(tsj)
          if tsj:type() == 'block' and tsj:tsnode():named_child_count() == 1 then strip_braces(tsj) end
        end,
      },
    })
    local java_block = utils.set_preset_for_statement({
      join = {
        format_tree = function(tsj)
          local parent = tsj:tsnode():parent()
          if parent and parent:type() == 'if_statement' and tsj:tsnode():named_child_count() == 1 then
            strip_braces(tsj)
          end
        end,
      },
    })

    -- GDScript: personal lang config (drop-in treesj lang file). Kept in lua/
    -- root, not plugins/custom, so lazy doesn't try to import it as a spec.
    local gdscript = require('treesj-gdscript')

    opts.langs = vim.tbl_deep_extend('force', opts.langs or {}, {
      javascript = langs,
      typescript = langs,
      tsx        = langs,
      java = {
        if_statement = if_statement,
        if_body = java_if_body,
        block = java_block,
      },
      gdscript = gdscript,
    })
  end,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        opts.mappings.n["<leader>j"] = { function() require("treesj").toggle() end, desc = "Toggle Split/Join" }
      end,
    },
  },
}
