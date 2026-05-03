local config = require("kb.config")

local M = {}

local INCLUDED_SECTIONS = { Active = true, Waiting = true, Someday = true }

-- Read todo.md content, preferring an open buffer over the file on disk so
-- unsaved edits are reflected in the calendar marks immediately.
local function read_todo_lines()
  local p = config.vault() .. "/todo.md"
  local target = vim.fn.resolve(vim.fn.fnamemodify(p, ":p"))
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.fn.resolve(vim.fn.fnamemodify(name, ":p")) == target then
        return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      end
    end
  end
  if vim.fn.filereadable(p) ~= 1 then
    return {}
  end
  return vim.fn.readfile(p)
end

-- Return a sorted, deduped list of YYYY-MM-DD dates that appear as `due:<date>`
-- in any line under sections ## Active / ## Waiting / ## Someday in todo.md.
function M.due_dates()
  local lines = read_todo_lines()
  local current_section = nil
  local set = {}
  for _, l in ipairs(lines) do
    local h = l:match("^##%s+(.+)$")
    if h then
      current_section = h
    elseif current_section and INCLUDED_SECTIONS[current_section] then
      for date in l:gmatch("due:(%d%d%d%d%-%d%d%-%d%d)") do
        set[date] = true
      end
    end
  end
  local out = {}
  for d in pairs(set) do table.insert(out, d) end
  table.sort(out)
  return out
end

return M
