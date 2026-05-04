local todo = require("kb.todo")

local M = {}

local WINBAR =
  " x cycle · X done · tw wait · ts someday · ta active · o new · ? help · q close "

local function relock(bufnr)
  if vim.b[bufnr].kb_todo_unlocked == 1 then return end
  vim.bo[bufnr].modifiable = false
end

local function with_unlock(bufnr, fn)
  local prev = vim.bo[bufnr].modifiable
  vim.bo[bufnr].modifiable = true
  local ok, err = pcall(fn)
  if not ok then
    vim.bo[bufnr].modifiable = prev
    error(err)
  end
  if vim.b[bufnr].kb_todo_unlocked ~= 1 then
    vim.bo[bufnr].modifiable = false
  end
end

local function map(bufnr, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
end

local function current_lnum()
  return vim.api.nvim_win_get_cursor(0)[1]
end

local function set_cursor(lnum)
  if not lnum then return end
  local last = vim.api.nvim_buf_line_count(0)
  if lnum > last then lnum = last end
  if lnum < 1 then lnum = 1 end
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
end

local function current_section()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i = current_lnum(), 1, -1 do
    local h = lines[i] and lines[i]:match("^## (.+)$")
    if h then return h end
  end
  return nil
end

-- Move task at cursor to `section`. If the task is in `## Done` and the
-- target is `## Active`, also reset state to `[ ]` (un-archive). If the task
-- is already in the target section, do nothing (avoids the "press w on a
-- Waiting task and watch it bounce to the bottom" UX bug).
local function move_to(bufnr, section)
  if current_section() == section then
    return  -- noop: already in target
  end
  with_unlock(bufnr, function()
    local ln = current_lnum()
    if section == "Active" then
      -- Un-archive: reset state if currently [x] or [-]
      local line = vim.api.nvim_buf_get_lines(bufnr, ln - 1, ln, false)[1] or ""
      local prefix, state, rest = line:match("^(%- %[)(.)(%].*)$")
      if prefix and (state == "x" or state == "-") then
        vim.api.nvim_buf_set_lines(bufnr, ln - 1, ln, false, { prefix .. " " .. rest })
      end
    end
    local new_lnum = todo.move_task(bufnr, ln, section)
    set_cursor(new_lnum)
  end)
end

function M.attach(bufnr)
  bufnr = bufnr or 0
  vim.bo[bufnr].modifiable = false
  vim.wo.winbar = WINBAR

  map(bufnr, "x", function()
    with_unlock(bufnr, function()
      set_cursor(todo.cycle_state(bufnr, current_lnum()))
    end)
  end, "kb-todo: cycle state (skips archive)")
  map(bufnr, "X", function()
    with_unlock(bufnr, function()
      set_cursor(todo.toggle_state(bufnr, current_lnum()))
    end)
  end, "kb-todo: toggle [ ] / [x] / [-]")
  map(bufnr, "tw", function() move_to(bufnr, "Waiting") end, "kb-todo: -> Waiting")
  map(bufnr, "ts", function() move_to(bufnr, "Someday") end, "kb-todo: -> Someday")
  map(bufnr, "ta", function() move_to(bufnr, "Active") end, "kb-todo: -> Active")
  map(bufnr, "dd", function()
    with_unlock(bufnr, function()
      local ln = current_lnum()
      local line = vim.api.nvim_buf_get_lines(bufnr, ln - 1, ln, false)[1] or ""
      if not line:match("^%- %[.%] ") then
        vim.notify("[kb] not a task line", vim.log.levels.WARN)
        return
      end
      vim.api.nvim_buf_set_lines(bufnr, ln - 1, ln, false, {})
      vim.cmd("write")
    end)
  end, "kb-todo: delete task")

  -- Determine which ## section the cursor is currently in.
  local function current_section_bounds()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local cursor = current_lnum()
    local start, stop = nil, #lines + 1
    for i = cursor, 1, -1 do
      if lines[i]:match("^## ") then start = i; break end
    end
    if not start then return nil, nil end
    for i = start + 1, #lines do
      if lines[i]:match("^## ") then stop = i; break end
    end
    return start, stop, lines
  end

  -- Find the line index just *after* the last task in the current section
  -- (skipping trailing blanks). If there are no tasks, return start+1.
  local function section_insert_point()
    local start, stop, lines = current_section_bounds()
    if not start then return nil end
    local insert_at = stop - 1
    while insert_at > start and lines[insert_at] == "" do
      insert_at = insert_at - 1
    end
    return insert_at + 1, lines
  end

  -- Edit windows: o / O briefly unlock and start insert
  local function start_edit_new_at_section_end()
    local at, _ = section_insert_point()
    if not at then
      vim.notify("[kb] cursor is not inside a ## section", vim.log.levels.WARN)
      return
    end
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, at - 1, at - 1, false, { "- [ ] " })
    vim.api.nvim_win_set_cursor(0, { at, 6 })
    vim.cmd("startinsert!")
  end
  local function start_edit_new_at_section_start()
    local start, _, _ = current_section_bounds()
    if not start then
      vim.notify("[kb] cursor is not inside a ## section", vim.log.levels.WARN)
      return
    end
    -- Insert immediately after the section header (and after any blank line right below it).
    vim.bo[bufnr].modifiable = true
    local insert_at = start + 1
    -- Skip a single blank line directly below the header so the new task sits on the first content line.
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if lines[insert_at] == "" then insert_at = insert_at + 1 end
    vim.api.nvim_buf_set_lines(bufnr, insert_at - 1, insert_at - 1, false, { "- [ ] " })
    vim.api.nvim_win_set_cursor(0, { insert_at, 6 })
    vim.cmd("startinsert!")
  end

  map(bufnr, "o", start_edit_new_at_section_end, "kb-todo: new task at end of section")
  map(bufnr, "O", start_edit_new_at_section_start, "kb-todo: new task at start of section")
  map(bufnr, "gu", function()
    vim.b[bufnr].kb_todo_unlocked = 1
    vim.bo[bufnr].modifiable = true
    vim.cmd("startinsert!")
  end, "kb-todo: unlock buffer for free editing (no auto-relock)")
  map(bufnr, "q", "<cmd>bd<cr>", "kb-todo: close")
  map(bufnr, "?", function() M.help() end, "kb-todo: help")

  vim.api.nvim_create_autocmd("InsertLeave", {
    buffer = bufnr,
    callback = function()
      if vim.b[bufnr].kb_todo_unlocked == 1 then return end
      vim.cmd("write")
      vim.bo[bufnr].modifiable = false
    end,
  })
end

function M.help()
  local lines = {
    " kb-todo modal keys ",
    "",
    "  x   cycle state  [ ] -> [/] -> [>] -> [?] -> [ ]   (skips archive)",
    "  X   toggle       [ ] -> [x] -> [-] -> [ ]          (archives on [x]/[-])",
    "  tw  move task to ## Waiting   (no-op if already there)",
    "  ts  move task to ## Someday   (no-op if already there)",
    "  ta  move task to ## Active    (resets [x]/[-] -> [ ])",
    "  dd  delete task line",
    "  o   new task at end of current section",
    "  O   new task at start of current section",
    "  gu  unlock buffer for free editing (no auto-relock this session)",
    "  q   close buffer",
    "  ?   this help",
    "",
    "  press <Esc>, q, or ? to close",
  }
  local width = 0
  for _, l in ipairs(lines) do if #l > width then width = #l end end
  width = width + 2
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " kb-todo help ",
    title_pos = "center",
  })

  -- Close on common keys
  for _, k in ipairs({ "<Esc>", "q", "?" }) do
    vim.keymap.set("n", k, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true })
  end
end

return M
