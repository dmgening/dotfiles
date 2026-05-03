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

local STATE_CYCLE = { " ", "/", "x", "-", ">", "?" }

local function state_index(ch)
  for i, s in ipairs(STATE_CYCLE) do
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

function M.move_task(bufnr, lnum, target_section)
  local lines = get_lines(bufnr)
  local task = lines[lnum]
  if not task or not task:match("^%- %[.%] ") then
    vim.notify("[kb] not a task line", vim.log.levels.WARN)
    return
  end
  table.remove(lines, lnum)
  local _, stop = find_section_bounds(lines, target_section)
  if not stop then
    vim.notify("[kb] section ## " .. target_section .. " not found", vim.log.levels.WARN)
    return
  end
  -- Insert just before the trailing blank line that precedes the next section header
  local insert_at = stop - 1
  while insert_at >= 1 and lines[insert_at] == "" do
    insert_at = insert_at - 1
  end
  insert_at = insert_at + 1
  table.insert(lines, insert_at, task)
  set_lines(bufnr, lines)
end

function M.toggle_state(bufnr, lnum)
  local lines = get_lines(bufnr)
  local task = lines[lnum]
  if not task then return end
  local prefix, state, rest = task:match("^(%- %[)(.)(%].*)$")
  if not prefix then
    vim.notify("[kb] not a task line", vim.log.levels.WARN)
    return
  end
  local new_state = state == "x" and " " or "x"
  lines[lnum] = prefix .. new_state .. rest
  set_lines(bufnr, lines)
  if new_state == "x" then
    M.move_task(bufnr, lnum, "Done")
  end
end

function M.cycle_state(bufnr, lnum)
  local lines = get_lines(bufnr)
  local task = lines[lnum]
  if not task then return end
  local prefix, state, rest = task:match("^(%- %[)(.)(%].*)$")
  if not prefix then
    vim.notify("[kb] not a task line", vim.log.levels.WARN)
    return
  end
  local idx = state_index(state) or 1
  local next_idx = (idx % #STATE_CYCLE) + 1
  local new_state = STATE_CYCLE[next_idx]
  lines[lnum] = prefix .. new_state .. rest
  set_lines(bufnr, lines)
  if new_state == "x" or new_state == "-" then
    M.move_task(bufnr, lnum, "Done")
  end
end

return M
