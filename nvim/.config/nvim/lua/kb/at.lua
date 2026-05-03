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
    -- Stub creation wired up in Task 17; for now: notify
    notify("not found: " .. resolved)
    return true
  end
  vim.cmd("edit " .. vim.fn.fnameescape(resolved))
  if anchor then
    vim.fn.search("^##\\s\\+" .. vim.fn.escape(anchor, "/.\\"), "")
  end
  return true
end

function M.jump()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local mention = M.parse(line, col)
  if not mention then
    notify("no @-mention under cursor")
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
  if not mention then
    notify("no @-mention under cursor")
    return
  end
  require("fzf-lua").grep({
    cwd = config.vault(),
    search = mention.raw,
    no_esc = true,
  })
end

return M
