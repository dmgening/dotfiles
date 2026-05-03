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

function M.substitute(lines, vars)
  local out = {}
  for _, line in ipairs(lines) do
    local replaced = line:gsub("{{(%w+)}}", function(name)
      local v = vars[name]
      if v == nil then return "{{" .. name .. "}}" end
      return v
    end)
    table.insert(out, replaced)
  end
  return out
end

function M.derive_title(target_abs)
  local stem = vim.fn.fnamemodify(target_abs, ":t:r")
  local with_spaces = stem:gsub("[%-_]", " ")
  -- Title case each word
  return with_spaces:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

local function notify(msg, level)
  vim.notify("[kb] " .. msg, level or vim.log.levels.WARN)
end

-- target_abs : absolute file path to create
-- canonical_or_rooted : the {{path}} value (e.g. "@people/peers/lena" for entities,
--                       "/domains/labeling/queries.md" for sub-files)
function M.create(target_abs, canonical_or_rooted)
  local vault = config.vault()

  -- Outside-vault guard
  if not vim.startswith(target_abs, vault .. "/") then
    notify("refusing to create file outside vault: " .. target_abs)
    return nil
  end

  -- Already-exists guard
  if vim.fn.filereadable(target_abs) == 1 then
    notify("already exists: " .. target_abs)
    return nil
  end

  local rel = target_abs:sub(#vault + 2)
  local choice = vim.fn.confirm("Create '" .. rel .. "'?", "&Yes\n&No")
  if choice ~= 1 then
    notify("not created")
    return nil
  end

  local template = M.template_for(target_abs)
  local vars = {
    title = M.derive_title(target_abs),
    date = os.date("%Y-%m-%d"),
    path = canonical_or_rooted,
  }
  local lines = M.substitute(template, vars)

  -- Ensure parent dirs
  local parent = vim.fn.fnamemodify(target_abs, ":h")
  vim.fn.mkdir(parent, "p")
  vim.fn.writefile(lines, target_abs)

  -- Refresh the index so the new entity is mentionable immediately.
  pcall(function() require("kb.index").refresh_file(target_abs) end)

  return target_abs
end

return M
