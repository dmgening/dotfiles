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

return M
