local M = {}

-- The kb source name; registered in M.setup so it's discoverable by name later.
M.SOURCE_NAME = "kb"

local function default_mappings(cmp)
  return cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping(function(fallback)
      local luasnip = require("luasnip")
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      local luasnip = require("luasnip")
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<C-Space>"] = cmp.mapping.complete(),
  })
end

function M.setup()
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  -- Register hand-written snippets with LuaSnip (filetype: markdown).
  luasnip.add_snippets("markdown", require("kb.snippets").all())

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = default_mappings(cmp),
    sources = cmp.config.sources({
      { name = "kb" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    }),
  })

  -- The custom `kb` source is registered below; call hook if defined.
  if M._register_kb_source then
    M._register_kb_source(cmp)
  end
end

-- ─────────────────────────────────────────────────────────────────
-- Custom `kb` cmp source

local Source = {}
Source.__index = Source

function M.new_source()
  return setmetatable({}, Source)
end

function Source:is_available()
  -- Buffer-attached only when the BufEnter autocmd registers us; assume yes.
  return true
end

function Source:get_trigger_characters()
  return { "@", "#" }
end

-- LSP CompletionItemKind constants (avoids requiring cmp at collection time).
local KIND_FILE    = 17  -- CompletionItemKind.File
local KIND_KEYWORD = 14  -- CompletionItemKind.Keyword

function Source:_collect_items(trigger)
  local index = require("kb.index")
  local items = {}
  if trigger == "@" or trigger == nil then
    for _, e in ipairs(index.entities()) do
      local filter_parts = { e.canonical }
      for _, a in ipairs(e.aliases or {}) do
        table.insert(filter_parts, a)
      end
      local label, insert
      if e.kind == "subfile" then
        local current = vim.api.nvim_buf_get_name(0)
        insert = self:_subfile_insert(e.abs_path, e.title, current)
        label = insert
      else
        label = e.canonical
        insert = e.canonical
      end
      table.insert(items, {
        label = label,
        insertText = insert,
        filterText = table.concat(filter_parts, " "),
        detail = e.title,
        kind = KIND_FILE,
        data = {
          kb_kind = e.kind,
          abs_path = e.abs_path,
          parent_canonical = e.parent_canonical,
          title = e.title,
        },
      })
    end
  end
  if trigger == "#" or trigger == nil then
    for _, tag in ipairs(index.tags()) do
      table.insert(items, {
        label = tag,
        insertText = tag,
        filterText = tag,
        kind = KIND_KEYWORD,
      })
    end
  end
  return items
end

function Source:_subfile_insert(target_abs, title, current_buf_abs)
  local target_dir = vim.fn.fnamemodify(target_abs, ":h")
  local current_dir = vim.fn.fnamemodify(current_buf_abs, ":h")
  local link_text = title
  if not link_text or link_text == "" then
    link_text = vim.fn.fnamemodify(target_abs, ":t:r")
  end
  if target_dir == current_dir then
    return "[" .. link_text .. "](" .. vim.fn.fnamemodify(target_abs, ":t") .. ")"
  end
  local config = require("kb.config")
  local rooted = "/" .. target_abs:sub(#config.vault() + 2)
  return "[" .. link_text .. "](" .. rooted .. ")"
end

-- isIncomplete=true so cmp re-asks the source as the user keeps typing after
-- the trigger character. This keeps the menu live with the latest cache
-- contents — e.g. a tag that was just added to another file and saved (which
-- triggers BufWritePost -> index.refresh_file) shows up on the next trigger
-- without a restart.
function Source:complete(params, callback)
  local trigger = params.context and params.context.trigger_character or nil
  callback({ items = self:_collect_items(trigger), isIncomplete = true })
end

-- Register in setup hook
M._register_kb_source = function(cmp)
  cmp.register_source(M.SOURCE_NAME, M.new_source())
end

return M
