local config = require("kb.config")

local M = {}

local AXES = { "people", "projects", "domains" }

local cache = {
  entities = nil,  -- list of entries
  tags = nil,      -- list of strings
  per_file_tags = {},  -- abs_path -> set of tags last seen
}

-- Recursively walk dir, collecting *.md files. Skips hidden dirs.
local function walk_md(dir, out)
  local handle = vim.uv.fs_scandir(dir)
  if not handle then return end
  while true do
    local name, t = vim.uv.fs_scandir_next(handle)
    if not name then break end
    if name:sub(1, 1) ~= "." then
      local full = dir .. "/" .. name
      if t == "directory" then
        walk_md(full, out)
      elseif t == "file" and name:sub(-3) == ".md" then
        table.insert(out, full)
      end
    end
  end
end

-- Convert an absolute path inside the vault to its canonical mention form.
-- Returns canonical, kind ("entity" | "subfile"), parent_canonical_or_nil.
local function classify(abs_path, vault)
  local rel = abs_path:sub(#vault + 2):gsub("%.md$", "")  -- strip vault prefix and .md
  local last = rel:match("[^/]+$")
  local parent = rel:match("(.+)/[^/]+$")
  if last == "index" then
    return "@" .. parent, "entity", nil
  end
  -- Determine if parent dir is a folder-form entity (parent/index.md exists).
  if parent then
    local parent_index = vault .. "/" .. parent .. "/index.md"
    if vim.fn.filereadable(parent_index) == 1 then
      return "@" .. rel, "subfile", "@" .. parent
    end
  end
  return "@" .. rel, "entity", nil
end

local function build_entities()
  local vault = config.vault()
  local files = {}
  for _, axis in ipairs(AXES) do
    walk_md(vault .. "/" .. axis, files)
  end
  local entries = {}
  for _, abs in ipairs(files) do
    local canonical, kind, parent_canonical = classify(abs, vault)
    table.insert(entries, {
      kind = kind,
      canonical = canonical,
      abs_path = abs,
      aliases = {},
      title = nil,
      parent_canonical = parent_canonical,
    })
  end
  return entries
end

function M.entities()
  if cache.entities == nil then
    cache.entities = build_entities()
  end
  return cache.entities
end

function M.tags()
  if cache.tags == nil then
    cache.tags = {}  -- tag scan added in Task 5
  end
  return cache.tags
end

function M.refresh()
  cache.entities = nil
  cache.tags = nil
  cache.per_file_tags = {}
end

return M
