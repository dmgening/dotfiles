local config = require("kb.config")

local M = {}

-- Buckets that live under people/. Everything else is treated as a top-level entity dir.
local PEOPLE_BUCKETS = { reports = true, peers = true, leadership = true, family = true }

-- Match @<bucket>/<name> or @<name>. Allows letters, digits, underscore, dash in bucket and name.
local MENTION_PATTERN = "@([%w_%-]+)/?([%w_%-]*)"

-- Parse the mention at column `col` (1-indexed) in `line`.
-- Returns { bucket, name, raw } or nil.
function M.parse(line, col)
  if not line or not col then return nil end
  local i = 1
  while true do
    local s, e, first, second = line:find(MENTION_PATTERN, i)
    if not s then return nil end
    if col >= s and col <= e then
      if second == "" then
        return { bucket = nil, name = first, raw = line:sub(s, e) }
      else
        return { bucket = first, name = second, raw = line:sub(s, e) }
      end
    end
    i = e + 1
  end
end

local function entity_dir(bucket)
  if PEOPLE_BUCKETS[bucket] then
    return config.vault() .. "/people/" .. bucket
  end
  return config.vault() .. "/" .. bucket
end

function M.resolve(mention)
  if not mention or not mention.bucket then return nil end
  local dir = entity_dir(mention.bucket)
  local flat = dir .. "/" .. mention.name .. ".md"
  if vim.fn.filereadable(flat) == 1 then
    return flat
  end
  local folder = dir .. "/" .. mention.name .. "/index.md"
  if vim.fn.filereadable(folder) == 1 then
    return folder
  end
  return nil
end

local function notify(msg, level)
  vim.notify("[kb] " .. msg, level or vim.log.levels.WARN)
end

function M.jump()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local mention = M.parse(line, col)
  if not mention then
    notify("no @-mention under cursor")
    return
  end
  if not mention.bucket then
    notify("specify bucket: e.g. @reports/" .. mention.name .. " (autocomplete will expand bare forms in Phase 1.5)")
    return
  end
  local p = M.resolve(mention)
  if not p then
    notify("not found: " .. mention.raw)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(p))
end

function M.backlinks()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local mention = M.parse(line, col)
  if not mention or not mention.bucket then
    notify("place cursor on a bucketed @-mention (e.g. @reports/vanya)")
    return
  end
  local search = "@" .. mention.bucket .. "/" .. mention.name
  require("fzf-lua").grep({
    cwd = config.vault(),
    search = search,
    no_esc = true,
  })
end

return M
