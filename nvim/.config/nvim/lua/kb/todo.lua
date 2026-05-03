local config = require("kb.config")

local M = {}

local SKELETON = {
  "# TODO",
  "",
  "## Active",
  "",
  "## Waiting",
  "",
  "## Someday",
  "",
  "## Done",
  "",
}

function M.path()
  return config.vault() .. "/todo.md"
end

local function read_or_skeleton()
  local p = M.path()
  if vim.fn.filereadable(p) == 1 then
    return vim.fn.readfile(p), false
  end
  return vim.deepcopy(SKELETON), true
end

local function find_section(lines, header)
  for i, line in ipairs(lines) do
    if line == header then
      return i
    end
  end
  return nil
end

local function ensure_active_section(lines)
  if find_section(lines, "## Active") then
    return lines
  end
  local insert_at = 1
  for i, line in ipairs(lines) do
    if line == "# TODO" then
      insert_at = i + 1
      break
    end
  end
  table.insert(lines, insert_at, "")
  table.insert(lines, insert_at + 1, "## Active")
  table.insert(lines, insert_at + 2, "")
  return lines
end

local function active_section_range(lines)
  local start = find_section(lines, "## Active")
  if not start then return nil, nil end
  local stop = #lines + 1
  for i = start + 1, #lines do
    if lines[i]:match("^## ") then
      stop = i
      break
    end
  end
  return start, stop
end

local function extract_tasks(daily_lines)
  local out = {}
  for _, line in ipairs(daily_lines) do
    if line:match("^%- %[ %] .+") then
      table.insert(out, line)
    end
  end
  return out
end

function M.sync(daily_path)
  if vim.fn.filereadable(daily_path) ~= 1 then
    return false
  end
  local daily_lines = vim.fn.readfile(daily_path)
  local candidates = extract_tasks(daily_lines)
  if #candidates == 0 then
    return false
  end

  local todo_lines, was_new = read_or_skeleton()
  todo_lines = ensure_active_section(todo_lines)

  local existing = {}
  for _, l in ipairs(todo_lines) do
    existing[l] = true
  end

  local _, active_stop = active_section_range(todo_lines)
  local insert_at = active_stop - 1
  while insert_at >= 1 and todo_lines[insert_at] == "" do
    insert_at = insert_at - 1
  end
  insert_at = insert_at + 1

  local added = false
  for _, task in ipairs(candidates) do
    if not existing[task] then
      table.insert(todo_lines, insert_at, task)
      insert_at = insert_at + 1
      existing[task] = true
      added = true
    end
  end

  if not added and not was_new then
    return false
  end

  if todo_lines[insert_at] ~= "" then
    table.insert(todo_lines, insert_at, "")
  end

  vim.fn.writefile(todo_lines, M.path())
  return added or was_new
end

function M.open()
  vim.cmd("edit " .. vim.fn.fnameescape(M.path()))
end

-- Non-archive states cycled by `x`. `[x]` (done) and `[-]` (cancelled) are
-- intentionally excluded so cycling never auto-archives — they're reachable
-- only via `X` (toggle_state).
local CYCLE_STATES = { " ", "/", ">", "?" }

-- Three-way ring used by `X`: empty -> done -> cancelled -> empty. Both `[x]`
-- and `[-]` archive to `## Done`; transitioning back to `[ ]` un-archives.
local TOGGLE_STATES = { " ", "x", "-" }

local ARCHIVE_STATES = { x = true, ["-"] = true }

local function index_of(list, ch)
  for i, s in ipairs(list) do
    if s == ch then return i end
  end
  return nil
end

local function get_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function set_lines(bufnr, lines)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.cmd("write")
end

local function find_section_bounds(lines, name)
  local header = "## " .. name
  local start = nil
  for i, l in ipairs(lines) do
    if l == header then start = i; break end
  end
  if not start then return nil, nil end
  local stop = #lines + 1
  for i = start + 1, #lines do
    if lines[i]:match("^## ") then stop = i; break end
  end
  return start, stop
end

local function section_at(lines, lnum)
  for i = lnum, 1, -1 do
    local h = lines[i] and lines[i]:match("^## (.+)$")
    if h then return h end
  end
  return nil
end

-- Move the task at `lnum` to the named section. Returns the new lnum on
-- success, or nil if the line wasn't a task or the section doesn't exist.
-- If the task is already at the bottom of the target section, it's a no-op
-- and the original lnum is returned unchanged.
function M.move_task(bufnr, lnum, target_section)
  local lines = get_lines(bufnr)
  local task = lines[lnum]
  if not task or not task:match("^%- %[.%] ") then
    vim.notify("[kb] not a task line", vim.log.levels.WARN)
    return nil
  end
  if section_at(lines, lnum) == target_section then
    return lnum  -- no-op: same section
  end
  table.remove(lines, lnum)
  local _, stop = find_section_bounds(lines, target_section)
  if not stop then
    vim.notify("[kb] section ## " .. target_section .. " not found", vim.log.levels.WARN)
    return nil
  end
  -- Insert just before the trailing blank line(s) that precede the next section.
  local insert_at = stop - 1
  while insert_at >= 1 and lines[insert_at] == "" do
    insert_at = insert_at - 1
  end
  insert_at = insert_at + 1
  table.insert(lines, insert_at, task)
  set_lines(bufnr, lines)
  return insert_at
end

-- Three-way toggle for `X`: [ ] -> [x] -> [-] -> [ ]. Archive states route
-- the task to `## Done`; transitioning back to `[ ]` while in Done un-archives
-- to `## Active`. Returns the new lnum (which may differ from `lnum` if the
-- task moved).
function M.toggle_state(bufnr, lnum)
  local lines = get_lines(bufnr)
  local task = lines[lnum]
  if not task then return nil end
  local prefix, state, rest = task:match("^(%- %[)(.)(%].*)$")
  if not prefix then
    vim.notify("[kb] not a task line", vim.log.levels.WARN)
    return nil
  end
  local idx = index_of(TOGGLE_STATES, state) or 1
  local new_state = TOGGLE_STATES[(idx % #TOGGLE_STATES) + 1]
  lines[lnum] = prefix .. new_state .. rest
  local was_in_done = section_at(lines, lnum) == "Done"
  set_lines(bufnr, lines)
  if ARCHIVE_STATES[new_state] then
    return M.move_task(bufnr, lnum, "Done") or lnum
  elseif was_in_done then
    return M.move_task(bufnr, lnum, "Active") or lnum
  end
  return lnum
end

-- Cycle through non-archive states only. If the task is currently in an
-- archive state (e.g. user is in `## Done`), wrap to the first non-archive
-- state, which causes the task to un-archive back to `## Active`.
function M.cycle_state(bufnr, lnum)
  local lines = get_lines(bufnr)
  local task = lines[lnum]
  if not task then return nil end
  local prefix, state, rest = task:match("^(%- %[)(.)(%].*)$")
  if not prefix then
    vim.notify("[kb] not a task line", vim.log.levels.WARN)
    return nil
  end
  local idx = index_of(CYCLE_STATES, state)
  local new_state
  if idx then
    new_state = CYCLE_STATES[(idx % #CYCLE_STATES) + 1]
  else
    new_state = CYCLE_STATES[1]  -- archive state -> back to fresh
  end
  lines[lnum] = prefix .. new_state .. rest
  local was_in_done = section_at(lines, lnum) == "Done"
  set_lines(bufnr, lines)
  if was_in_done then
    return M.move_task(bufnr, lnum, "Active") or lnum
  end
  return lnum
end

return M
