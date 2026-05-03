local config = require("kb.config")

local M = {}

-- pending[bufnr] = list of tmp file paths inserted into that buffer but not
-- yet migrated. Cleared on BufUnload.
M.pending = {}

-- Test seam: tests can override _test_pngpaste to fake clipboard behavior.
-- Returns true if a PNG was written to `tmp_path`, false otherwise.
function M._pngpaste(tmp_path)
  if M._test_pngpaste then return M._test_pngpaste(tmp_path) end
  local cmd = string.format("pngpaste %s 2>/dev/null", vim.fn.shellescape(tmp_path))
  local result = os.execute(cmd)
  if result ~= 0 and result ~= true then return false end  -- Lua 5.1 returns int, 5.4 returns bool
  if vim.fn.filereadable(tmp_path) ~= 1 then return false end
  if vim.fn.getfsize(tmp_path) <= 0 then return false end
  return true
end

local function uuid()
  local now = vim.fn.reltime()
  return string.format("%d-%d-%d", now[1] or os.time(), now[2] or 0, math.random(1, 1e9))
end

local function insert_link_at_cursor(link_text)
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local new_line = line:sub(1, col) .. link_text .. line:sub(col + 1)
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row, col + #link_text })
end

function M.paste_or_fallthrough(key)
  local tmp = "/tmp/kb-paste-" .. uuid() .. ".png"
  if M._pngpaste(tmp) then
    local link = string.format("![](file://%s)", tmp)
    insert_link_at_cursor(link)
    local buf = vim.api.nvim_get_current_buf()
    M.pending[buf] = M.pending[buf] or {}
    table.insert(M.pending[buf], tmp)
    return
  end
  -- Fallthrough: ensure no leftover tmp file.
  if vim.fn.filereadable(tmp) == 1 then vim.fn.delete(tmp) end
  -- Execute the default behavior for the original key.
  vim.cmd("normal! " .. key)
end

function M.pending_for(buf)
  return M.pending[buf] or {}
end

-- Returns the next available vault/images/<basename>.png with a numeric suffix
-- if collisions exist (-1, -2, ...).
local function unique_vault_path()
  local stamp = os.date("%Y-%m-%d-%H%M%S")
  local dir = config.vault() .. "/images"
  vim.fn.mkdir(dir, "p")
  local p = dir .. "/" .. stamp .. ".png"
  if vim.fn.filereadable(p) ~= 1 then return p, stamp .. ".png" end
  local n = 1
  while true do
    local cand = dir .. "/" .. stamp .. "-" .. n .. ".png"
    if vim.fn.filereadable(cand) ~= 1 then return cand, stamp .. "-" .. n .. ".png" end
    n = n + 1
  end
end

function M.on_buf_write_pre(buf)
  local tmps = M.pending[buf]
  if not tmps or #tmps == 0 then return end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local new_lines = vim.deepcopy(lines)
  local mutated = false
  for _, tmp in ipairs(tmps) do
    local needle = "file://" .. tmp
    local referenced = false
    for i, l in ipairs(new_lines) do
      if l:find(needle, 1, true) then
        referenced = true
        if not mutated then
          -- Defer the actual swap until we know the new path.
        end
        local vault_path, basename = unique_vault_path()
        os.rename(tmp, vault_path)
        new_lines[i] = (l:gsub(vim.pesc(needle), "/images/" .. basename))
        mutated = true
      end
    end
    if not referenced then
      if vim.fn.filereadable(tmp) == 1 then vim.fn.delete(tmp) end
    end
  end
  if mutated then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
  end
  M.pending[buf] = {}
end

function M.on_buf_unload(buf)
  local tmps = M.pending[buf]
  if not tmps then return end
  for _, tmp in ipairs(tmps) do
    if vim.fn.filereadable(tmp) == 1 then vim.fn.delete(tmp) end
  end
  M.pending[buf] = nil
end

function M.cleanup_all()
  for _, tmps in pairs(M.pending) do
    for _, tmp in ipairs(tmps) do
      if vim.fn.filereadable(tmp) == 1 then vim.fn.delete(tmp) end
    end
  end
  M.pending = {}
end

return M
