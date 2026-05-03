local config = require("kb.config")

local M = {}

local DEFAULT_TEMPLATE = { "# {{title}}", "" }

-- Walk from the most-specific subdir up to the templates root, looking for entity.md.
function M.template_for(target_abs)
  local vault = config.vault()
  if not vim.startswith(target_abs, vault .. "/") then
    return DEFAULT_TEMPLATE
  end
  local rel = target_abs:sub(#vault + 2)
  local rel_dir = rel:match("(.+)/[^/]+$") or ""

  local segments = {}
  for seg in rel_dir:gmatch("[^/]+") do
    table.insert(segments, seg)
  end

  -- Try most-specific first, walk up to root.
  while true do
    local candidate
    if #segments > 0 then
      candidate = vault .. "/.templates/" .. table.concat(segments, "/") .. "/entity.md"
    else
      candidate = vault .. "/.templates/entity.md"
    end
    if vim.fn.filereadable(candidate) == 1 then
      return vim.fn.readfile(candidate)
    end
    if #segments == 0 then break end
    table.remove(segments)
  end

  return DEFAULT_TEMPLATE
end

return M
