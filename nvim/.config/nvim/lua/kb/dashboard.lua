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

-- Open the dashboard tab. Left = year calendar (~30%), right = todo.md (~70%).
function M.open()
  local todo_path = config.vault() .. "/todo.md"
  -- Ensure todo.md exists (so :edit doesn't create an empty unnamed buffer).
  if vim.fn.filereadable(todo_path) ~= 1 then
    vim.fn.mkdir(vim.fn.fnamemodify(todo_path, ":h"), "p")
    vim.fn.writefile({ "# TODO", "", "## Active", "", "## Waiting", "", "## Someday", "", "## Done", "" }, todo_path)
  end
  -- Open todo first (will end up on the right).
  vim.cmd("tabnew " .. vim.fn.fnameescape(todo_path))
  local content_win = vim.api.nvim_get_current_win()
  local content_buf = vim.api.nvim_get_current_buf()
  -- Open calendar to the LEFT of todo.
  vim.cmd("vertical leftabove Calendar -view=year")
  local calendar_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(calendar_win, math.floor(vim.o.columns * 0.3))
  -- Bind <CR>, ?, q on the calendar buffer (current).
  vim.keymap.set("n", "<CR>", function() M.jump_calendar_date() end, {
    buffer = 0,
    desc = "kb dashboard: open daily for date under cursor",
  })
  vim.keymap.set("n", "?", function() M.help() end, { buffer = 0, desc = "kb dashboard: help" })
  vim.keymap.set("n", "q", function() vim.cmd("tabclose") end, { buffer = 0, desc = "kb dashboard: close" })
  -- Bind 't' on the content (right) buffer.
  vim.keymap.set("n", "t", function() M.toggle_content() end, { buffer = content_buf, desc = "kb dashboard: toggle todo/daily" })
  M.rebuild_marks()
end

-- Pure: given a date string, open the daily in the current window if the file
-- exists; else notify. Used by jump_calendar_date and directly testable.
function M.jump_calendar_date_for(date)
  local p = config.vault() .. "/daily/" .. date .. ".md"
  if vim.fn.filereadable(p) ~= 1 then
    vim.notify("[kb] no daily for " .. date, vim.log.levels.INFO)
    return
  end
  -- Switch to the dashboard's content window (the non-calendar one) before opening.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "calendar" then
      vim.api.nvim_set_current_win(win)
      break
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(p))
end

-- Read date under cursor in calendar-vim's pane and dispatch.
-- calendar-vim exposes b:CalendarYear / b:CalendarMonth on the buffer; the day
-- number is the bare integer at the cursor position. If parsing fails, no-op.
function M.jump_calendar_date()
  local year = vim.b.CalendarYear
  local month = vim.b.CalendarMonth
  if not (year and month) then return end
  local day = vim.fn.expand("<cword>"):match("^(%d%d?)$")
  if not day then return end
  local date = string.format("%04d-%02d-%02d", year, tonumber(month), tonumber(day))
  M.jump_calendar_date_for(date)
end

-- Toggle the content pane between todo.md and today's daily. Operates on the
-- current window/buffer, so the caller must press `t` while focused on the
-- content pane (the `t` keymap is buffer-local on the content buffer).
function M.toggle_content()
  local config_mod = require("kb.config")
  local todo_path = config_mod.vault() .. "/todo.md"
  local current = vim.api.nvim_buf_get_name(0)
  if vim.fn.resolve(vim.fn.fnamemodify(current, ":p")) == vim.fn.resolve(vim.fn.fnamemodify(todo_path, ":p")) then
    -- Currently on todo → switch to today's daily (creates if missing).
    require("kb.daily").open_today()
    vim.keymap.set("n", "t", function() M.toggle_content() end, { buffer = 0, desc = "kb dashboard: toggle todo/daily" })
  else
    vim.cmd("edit " .. vim.fn.fnameescape(todo_path))
    vim.keymap.set("n", "t", function() M.toggle_content() end, { buffer = 0, desc = "kb dashboard: toggle todo/daily" })
  end
end

-- Backward-compatible alias for tests/external callers.
M.toggle_left = M.toggle_content

-- Rebuild the calendar mark set from todo.md. Registers g:calendar_sign as a
-- vim funcref (via vim.fn['']) that returns "*" for marked dates, "" otherwise.
function M.rebuild_marks()
  local dates = M.due_dates()
  local set = {}
  for _, d in ipairs(dates) do set[d] = true end
  -- Define a Vim global function and store its funcref in g:calendar_sign.
  -- (calendar-vim calls it as g:calendar_sign(day, month, year).)
  _G.kb_calendar_sign = function(day, month, year)
    local key = string.format("%04d-%02d-%02d", year, month, day)
    return set[key] and "*" or ""
  end
  vim.cmd([[
    function! KbCalendarSign(day, month, year) abort
      return v:lua.kb_calendar_sign(a:day, a:month, a:year)
    endfunction
  ]])
  vim.g.calendar_sign = "KbCalendarSign"
  -- Force calendar-vim to redraw if a calendar buffer is visible.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.bo[buf].filetype
      if ft == "calendar" then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            pcall(vim.api.nvim_win_call, win, function() vim.cmd("CalendarVR") end)
          end
        end
      end
    end
  end
end

local HELP_LINES = {
  "  kb dashboard ",
  "",
  "  Content pane (right):",
  "    t           toggle todo ⇄ today's daily",
  "",
  "  Calendar pane (left):",
  "    <CR>        open daily for date under cursor (if it exists)",
  "    ?           this help",
  "    q           close dashboard",
  "",
  "  Press any key to close this panel.",
}

function M.help()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, HELP_LINES)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  local width = 0
  for _, l in ipairs(HELP_LINES) do
    if #l > width then width = #l end
  end
  width = width + 2
  local height = #HELP_LINES
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " kb dashboard help ",
    title_pos = "center",
  })
  -- Any key closes the float.
  vim.keymap.set("n", "<buffer>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
  -- Common keys explicitly.
  for _, k in ipairs({ "<Esc>", "q", "<CR>", "?" }) do
    vim.keymap.set("n", k, function() vim.api.nvim_win_close(win, true) end, { buffer = buf, nowait = true })
  end
end

return M
