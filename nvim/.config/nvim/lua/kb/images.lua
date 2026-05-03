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
  local ok = os.execute(cmd) == 0 or os.execute(cmd) == true  -- Lua 5.1 vs 5.4
  if not ok then return false end
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

return M
