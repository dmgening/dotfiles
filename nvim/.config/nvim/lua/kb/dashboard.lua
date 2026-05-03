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

-- Open the dashboard tab. Left = todo.md (~70%), right = year calendar.
function M.open()
  local todo_path = config.vault() .. "/todo.md"
  -- Ensure todo.md exists (so :edit doesn't create an empty unnamed buffer).
  if vim.fn.filereadable(todo_path) ~= 1 then
    vim.fn.mkdir(vim.fn.fnamemodify(todo_path, ":h"), "p")
    vim.fn.writefile({ "# TODO", "", "## Active", "", "## Waiting", "", "## Someday", "", "## Done", "" }, todo_path)
  end
  vim.cmd("tabnew " .. vim.fn.fnameescape(todo_path))
  vim.cmd("vertical rightbelow Calendar -view=year")
  -- Resize right pane to ~30% of total columns.
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(right_win, math.floor(vim.o.columns * 0.3))
  -- Set buffer-local 't' on the left window.
  local left_win = vim.api.nvim_tabpage_list_wins(0)[1]
  local left_buf = vim.api.nvim_win_get_buf(left_win)
  vim.keymap.set("n", "t", function() M.toggle_left() end, { buffer = left_buf, desc = "kb dashboard: toggle todo/daily" })
end

function M.toggle_left()
  local config_mod = require("kb.config")
  local todo_path = config_mod.vault() .. "/todo.md"
  local current = vim.api.nvim_buf_get_name(0)
  if vim.fn.resolve(vim.fn.fnamemodify(current, ":p")) == vim.fn.resolve(vim.fn.fnamemodify(todo_path, ":p")) then
    -- Currently on todo → switch to today's daily (creates if missing).
    require("kb.daily").open_today()
    -- Re-bind 't' on the new buffer.
    vim.keymap.set("n", "t", function() M.toggle_left() end, { buffer = 0, desc = "kb dashboard: toggle todo/daily" })
  else
    vim.cmd("edit " .. vim.fn.fnameescape(todo_path))
    vim.keymap.set("n", "t", function() M.toggle_left() end, { buffer = 0, desc = "kb dashboard: toggle todo/daily" })
  end
end

return M
