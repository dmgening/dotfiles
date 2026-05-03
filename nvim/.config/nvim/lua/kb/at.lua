local config = require("kb.config")

local M = {}

-- Match @ followed by a path-like sequence (alphanumerics, underscore, dash, slash).
-- Left-anchored so it doesn't match the @ in email-like text (a@b.com).
-- Trailing slash is allowed for in-flight typing but yields the path without it.
local MENTION_PATTERN = "([%s%p]?)@([%w_%-/]+)"

-- Parse the mention at column `col` (1-indexed) in `line`.
-- Returns { path, raw } or nil.
function M.parse(line, col)
  if not line or not col then return nil end
  local i = 1
  while true do
    local s, e, prefix, path = line:find(MENTION_PATTERN, i)
    if not s then return nil end
    -- prefix must be empty (start-of-line) or whitespace/punctuation that's not alnum/_-
    -- Lua's pattern already enforces this via [%s%p]?, but emails like a@b.com
    -- have prefix='a' which fails [%s%p]. So we additionally check that if the
    -- character immediately before @ exists and is alphanumeric/_, we skip.
    local at_pos = s + #prefix
    local before = at_pos > 1 and line:sub(at_pos - 1, at_pos - 1) or ""
    if before == "" or before:match("[%s%p]") then
      -- Trim trailing slash from path (in-flight typing)
      local clean_path = path:gsub("/$", "")
      if clean_path ~= "" and col >= at_pos and col <= e then
        return {
          path = clean_path,
          raw = "@" .. clean_path,
        }
      end
    end
    i = e + 1
  end
end

function M.resolve(mention)
  if not mention or not mention.path or mention.path == "" then return nil end
  local vault = config.vault()
  local flat = vault .. "/" .. mention.path .. ".md"
  if vim.fn.filereadable(flat) == 1 then
    return flat
  end
  local folder = vault .. "/" .. mention.path .. "/index.md"
  if vim.fn.filereadable(folder) == 1 then
    return folder
  end
  return nil
end

local function notify(msg, level)
  vim.notify("[kb] " .. msg, level or vim.log.levels.WARN)
end

-- Parse a markdown link [text](path) such that `col` (1-indexed) lies anywhere
-- between the opening `[` and the closing `)`. Returns { text, path } or nil.
function M.parse_link(line, col)
  if not line or not col then return nil end
  local i = 1
  while true do
    local s, e, text, path = line:find("%[([^%]]+)%]%(([^%)]+)%)", i)
    if not s then return nil end
    if col >= s and col <= e then
      return { text = text, path = path }
    end
    i = e + 1
  end
end

-- Resolve a parsed link's path to either an absolute file path (for local files)
-- or the original URL string (for http(s)). Returns (resolved_path, anchor_or_nil).
-- For http(s) URLs, returns (url, nil).
function M.resolve_link(link, current_buf_abs)
  local p = link.path
  if p:match("^https?://") then
    return p, nil
  end
  local anchor = nil
  local hash = p:find("#", 1, true)
  if hash then
    anchor = p:sub(hash + 1)
    p = p:sub(1, hash - 1)
  end
  if p:sub(1, 1) == "/" then
    -- Vault-rooted
    return config.vault() .. p, anchor
  end
  -- Relative to current buffer's directory
  local dir = vim.fn.fnamemodify(current_buf_abs, ":h")
  return vim.fs.normalize(dir .. "/" .. p), anchor
end

function M.jump_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local link = M.parse_link(line, col)
  if not link then
    return false  -- caller (jump dispatcher) decides what to do
  end
  local current = vim.api.nvim_buf_get_name(0)
  local resolved, anchor = M.resolve_link(link, current)
  if resolved:match("^https?://") then
    vim.ui.open(resolved)
    return true
  end
  if vim.fn.filereadable(resolved) ~= 1 then
    -- Stub-create using the rooted form as {{path}}
    local rooted_path = "/" .. resolved:sub(#config.vault() + 2)
    local created = require("kb.stub").create(resolved, rooted_path)
    if created then
      vim.cmd("edit " .. vim.fn.fnameescape(created))
    end
    return true
  end
  vim.cmd("edit " .. vim.fn.fnameescape(resolved))
  if anchor then
    vim.fn.search("^##\\s\\+" .. vim.fn.escape(anchor, "/.\\"), "")
  end
  return true
end

function M.jump()
  -- Try markdown link first (more specific than @-mention)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  if M.parse_link(line, col) then
    M.jump_link()
    return
  end
  -- Fall through to @-mention
  local mention = M.parse(line, col)
  if not mention then
    notify("no link or mention under cursor")
    return
  end
  local p = M.resolve(mention)
  if not p then
    -- Stub-create: build target path (always flat per design §7a.4)
    local target = config.vault() .. "/" .. mention.path .. ".md"
    local created = require("kb.stub").create(target, mention.raw)
    if created then
      vim.cmd("edit " .. vim.fn.fnameescape(created))
    end
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(p))
end

-- Parse a #tag at cursor. Same boundary rules as the index scanner: char
-- before # must not be alphanumeric/underscore (so `abc#notatag` is rejected
-- but ` #realtag`, `(#realtag)`, start-of-line all match). Tag must start
-- with a letter; allowed chars are letters, digits, /, _, -.
-- Returns { tag, raw } or nil. (`tag` is the bare identifier without `#`,
-- `raw` is the full `#tag` for searching.)
function M.parse_tag(line, col)
  if not line or not col then return nil end
  local i = 1
  while true do
    local s, e = line:find("#%a[%w/_%-]*", i)
    if not s then return nil end
    local before = s > 1 and line:sub(s - 1, s - 1) or ""
    if before == "" or not before:match("[%w_]") then
      if col >= s and col <= e then
        return { tag = line:sub(s + 1, e), raw = line:sub(s, e) }
      end
    end
    i = e + 1
  end
end

function M.backlinks()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  local tag = M.parse_tag(line, col)
  if tag then
    require("fzf-lua").grep({
      cwd = config.vault(),
      search = tag.raw,
      no_esc = true,
    })
    return
  end

  local mention = M.parse(line, col)
  if mention then
    require("fzf-lua").grep({
      cwd = config.vault(),
      search = mention.raw,
      no_esc = true,
    })
    return
  end

  if M.parse_link(line, col) then
    M.backlinks_link()
    return
  end

  notify("no link/mention/tag under cursor")
end

-- Run a shell command and return stdout as a list of lines.
local function shell_lines(cmd)
  local out = {}
  local handle = io.popen(cmd, "r")
  if not handle then return out end
  for line in handle:lines() do table.insert(out, line) end
  handle:close()
  return out
end

local function shell_escape(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Resolve a captured link path relative to source_dir to an absolute file path.
-- Vault-rooted (/foo) → vault root; else relative to source_dir.
local function resolve_captured(captured, source_dir)
  if captured:sub(1, 1) == "/" then
    return config.vault() .. captured
  end
  return vim.fs.normalize(source_dir .. "/" .. captured)
end

-- Return all backlinks (in any syntactic form: rooted, relative, bare) whose
-- target resolves to target_abs. Each result is { file, line, lnum, text }.
function M.backlinks_for_target(target_abs)
  local basename = vim.fn.fnamemodify(target_abs, ":t")
  -- Coarse rg pre-filter: look for "](" + (any non-) chars + basename + ")"
  -- on a single line. -- vimgrep gives file:lnum:col:text format.
  local pattern = "\\]\\([^)]*" .. vim.fn.escape(basename, [[\.]]) .. "\\)"
  local cmd = string.format(
    "rg --vimgrep --no-heading --color=never --no-config -e %s %s 2>/dev/null",
    shell_escape(pattern),
    shell_escape(config.vault())
  )
  local lines = shell_lines(cmd)
  local results = {}
  for _, l in ipairs(lines) do
    -- vimgrep format: file:lnum:col:text
    local file, lnum_str, _, text = l:match("^([^:]+):(%d+):(%d+):(.*)$")
    if file and text then
      -- Extract every (path) capture in this line and check if any resolves to target.
      for captured in text:gmatch("%]%(([^)]+)%)") do
        local abs = resolve_captured(captured, vim.fn.fnamemodify(file, ":h"))
        if abs == target_abs then
          table.insert(results, {
            file = file,
            lnum = tonumber(lnum_str),
            line = text,
            text = text,
          })
          break  -- one result per line is enough
        end
      end
    end
  end
  return results
end

-- Cursor on a [text](path) link: resolve the target and find all backlinks.
function M.backlinks_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local link = M.parse_link(line, col)
  if not link then return false end
  if link.path:match("^https?://") or link.path:match("^mailto:") then
    notify("backlinks not supported for URL targets", vim.log.levels.INFO)
    return true
  end
  local current = vim.api.nvim_buf_get_name(0)
  local target_abs, _ = M.resolve_link(link, current)
  local results = M.backlinks_for_target(target_abs)
  if #results == 0 then
    notify("no backlinks for " .. target_abs)
    return true
  end
  -- Surface in fzf-lua quickfix-style picker.
  local items = {}
  for _, r in ipairs(results) do
    table.insert(items, string.format("%s:%d: %s", r.file, r.lnum, r.text))
  end
  require("fzf-lua").fzf_exec(items, {
    prompt = "Backlinks> ",
    actions = {
      ["default"] = function(selected)
        if not selected[1] then return end
        local file, lnum = selected[1]:match("^([^:]+):(%d+):")
        if file then
          vim.cmd("edit " .. vim.fn.fnameescape(file))
          if lnum then vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 }) end
        end
      end,
    },
  })
  return true
end

return M
