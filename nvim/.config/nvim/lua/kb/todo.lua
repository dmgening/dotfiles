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

return M
