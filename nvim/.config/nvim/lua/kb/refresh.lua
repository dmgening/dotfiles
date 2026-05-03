local M = {}

-- Returns the list of loaded bufnrs whose name normalizes to abs_path.
local function buffers_for(abs_path)
  local target = vim.fn.resolve(vim.fn.fnamemodify(abs_path, ":p"))
  local out = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.fn.resolve(vim.fn.fnamemodify(name, ":p")) == target then
        table.insert(out, buf)
      end
    end
  end
  return out
end

-- Reload the buffer for abs_path (if any) from disk. Preserves view per window
-- showing the buffer. Skips and notifies if any matching buffer is modified.
function M.path(abs_path)
  local bufs = buffers_for(abs_path)
  if #bufs == 0 then return end
  for _, buf in ipairs(bufs) do
    if vim.bo[buf].modified then
      vim.notify("[kb] " .. abs_path .. " has unsaved edits; not refreshing", vim.log.levels.WARN)
      return
    end
  end
  if vim.fn.filereadable(abs_path) ~= 1 then return end
  local lines = vim.fn.readfile(abs_path)
  for _, buf in ipairs(bufs) do
    -- Save view per window currently showing this buffer.
    local views = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == buf then
        views[win] = vim.api.nvim_win_call(win, function() return vim.fn.winsaveview() end)
      end
    end
    -- Replace lines without firing BufRead/BufWrite cascades.
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false
    for win, view in pairs(views) do
      vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end)
    end
  end
end

-- Apply lines_fn to the current contents of abs_path and write the result.
-- If a loaded buffer points at abs_path, modify the buffer's lines and mark
-- it dirty (user saves later). Otherwise read+write the file on disk.
function M.write_through(abs_path, lines_fn)
  local bufs = buffers_for(abs_path)
  if #bufs > 0 then
    local buf = bufs[1]
    local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local new = lines_fn(current)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new)
    vim.bo[buf].modified = true
    return
  end
  local current = {}
  if vim.fn.filereadable(abs_path) == 1 then
    current = vim.fn.readfile(abs_path)
  end
  local new = lines_fn(current)
  vim.fn.mkdir(vim.fn.fnamemodify(abs_path, ":h"), "p")
  vim.fn.writefile(new, abs_path)
end

return M
