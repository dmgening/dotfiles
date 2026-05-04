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

-- Read the first frontmatter block (--- ... ---) at the very top of file.
-- Returns { title = string?, aliases = { string, ... } } even on malformed input.
local function parse_frontmatter(abs_path)
  local out = { title = nil, aliases = {} }
  local f = io.open(abs_path, "r")
  if not f then return out end

  local first = f:read("*l")
  if first ~= "---" then
    f:close()
    return out
  end

  local lines = {}
  while true do
    local line = f:read("*l")
    if line == nil then
      -- EOF without closing ---: malformed, return defaults
      f:close()
      return { title = nil, aliases = {} }
    end
    if line == "---" then break end
    table.insert(lines, line)
  end
  f:close()

  local in_aliases_block = false
  for _, line in ipairs(lines) do
    if in_aliases_block then
      local item = line:match("^%s*%-%s*(.+)%s*$")
      if item then
        table.insert(out.aliases, item)
      else
        in_aliases_block = false
      end
    end
    if not in_aliases_block then
      -- title: Foo
      local title = line:match("^title:%s*(.-)%s*$")
      if title and title ~= "" then
        -- strip surrounding quotes if any
        title = title:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
        out.title = title
      end
      -- aliases: [a, b, c]   (inline)
      local inline = line:match("^aliases:%s*%[(.-)%]%s*$")
      if inline then
        for item in inline:gmatch("([^,]+)") do
          table.insert(out.aliases, (item:gsub("^%s+", ""):gsub("%s+$", "")))
        end
      else
        -- aliases:    (block start)
        if line:match("^aliases:%s*$") then
          in_aliases_block = true
        end
      end
    end
  end

  return out
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
    local fm = parse_frontmatter(abs)
    table.insert(entries, {
      kind = kind,
      canonical = canonical,
      abs_path = abs,
      aliases = fm.aliases,
      title = fm.title,
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

-- Tag regex: `#tag` where the char before # is start-of-line, whitespace, or
-- punctuation (not alphanumeric or underscore). Uses PCRE \K to reset match
-- start so --only-matching gives just the #tag without the boundary char.
local TAG_PCRE = [[(?:^|[^A-Za-z0-9_])\K(#[A-Za-z][A-Za-z0-9/_-]*)]]

local function scan_tags()
  if vim.fn.executable("rg") == 0 then
    vim.notify("[kb] rg not found, tag completion disabled", vim.log.levels.WARN)
    return {}, {}
  end
  local vault = config.vault()
  -- Use --only-matching + --with-filename for clean file:#tag output.
  -- \K ensures the match starts at #, so no boundary char in output.
  local cmd = {
    "rg", "--pcre2", "--only-matching", "--with-filename", "--no-heading",
    TAG_PCRE,
    vault,
    "--glob", "!.git/**",
    "--glob", "!.trash/**",
    "--glob", "!.templates/**",
  }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 and result.code ~= 1 then
    vim.notify("[kb] rg tag scan failed: " .. (result.stderr or ""), vim.log.levels.WARN)
    return {}, {}
  end
  local set = {}
  local per_file = {}
  for line in (result.stdout or ""):gmatch("[^\n]+") do
    -- Format: /path/to/file.md:#tagname
    local file, tag = line:match("^(.-):([#][A-Za-z][%w/_%-]*)$")
    if file and tag then
      set[tag] = true
      per_file[file] = per_file[file] or {}
      per_file[file][tag] = true
    end
  end
  local tags = {}
  for tag in pairs(set) do
    table.insert(tags, tag)
  end
  return tags, per_file
end

function M.tags()
  if cache.tags == nil then
    local tags, per_file = scan_tags()
    cache.tags = tags
    cache.per_file_tags = per_file
  end
  return cache.tags
end

function M.refresh()
  cache.entities = nil
  cache.tags = nil
  cache.per_file_tags = {}
end

-- Scan a single file for tags (used by refresh_file).
local function tags_in_file(abs_path)
  local result = {}
  local f = io.open(abs_path, "r")
  if not f then return result end
  local content = f:read("*a")
  f:close()
  -- Lua patterns can't do PCRE lookahead, so iterate manually.
  local i = 1
  while true do
    local s, e = content:find("#%a[%w/_%-]*", i)
    if not s then break end
    local before = s > 1 and content:sub(s - 1, s - 1) or ""
    if before == "" or not before:match("[%w_]") then
      result[content:sub(s, e)] = true
    end
    i = e + 1
  end
  return result
end

function M.refresh_file(abs_path)
  if not abs_path then return end
  local vault = config.vault()
  if not vim.startswith(abs_path, vault .. "/") then return end

  -- Make sure caches are populated before we mutate them.
  M.entities()
  M.tags()

  -- ENTITY UPDATE
  -- Determine if this path is in an axis (people/projects/domains).
  local rel = abs_path:sub(#vault + 2)
  local axis = rel:match("^([^/]+)/")
  local in_axis = false
  for _, a in ipairs(AXES) do
    if a == axis then in_axis = true end
  end

  if in_axis then
    local canonical, kind, parent_canonical = classify(abs_path, vault)
    local fm = parse_frontmatter(abs_path)
    local found = false
    for i_, e in ipairs(cache.entities) do
      if e.abs_path == abs_path then
        cache.entities[i_] = {
          kind = kind,
          canonical = canonical,
          abs_path = abs_path,
          aliases = fm.aliases,
          title = fm.title,
          parent_canonical = parent_canonical,
        }
        found = true
        break
      end
    end
    if not found then
      table.insert(cache.entities, {
        kind = kind,
        canonical = canonical,
        abs_path = abs_path,
        aliases = fm.aliases,
        title = fm.title,
        parent_canonical = parent_canonical,
      })
    end
  end

  -- TAG UPDATE
  local new_tags = tags_in_file(abs_path)
  cache.per_file_tags[abs_path] = new_tags

  -- Rebuild global tag set from per_file_tags
  local set = {}
  for _, file_tags in pairs(cache.per_file_tags) do
    for tag in pairs(file_tags) do
      set[tag] = true
    end
  end
  local out = {}
  for tag in pairs(set) do
    table.insert(out, tag)
  end
  cache.tags = out
end

return M
