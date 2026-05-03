local config = require("kb.config")

local M = {}

local function date_or_today(date)
  return date or os.date("%Y-%m-%d")
end

function M.path(date)
  return config.vault() .. "/daily/" .. date_or_today(date) .. ".md"
end

function M.ensure(date)
  local d = date_or_today(date)
  local p = M.path(d)
  if vim.fn.filereadable(p) == 1 then
    return p
  end
  local parent = vim.fn.fnamemodify(p, ":h")
  vim.fn.mkdir(parent, "p")
  vim.fn.writefile({
    "---",
    "date: " .. d,
    "---",
    "",
    "# " .. d,
    "",
  }, p)
  return p
end

function M.append_section(text, date)
  local d = date_or_today(date)
  local p = M.ensure(d)
  local existing = vim.fn.readfile(p)
  local hhmm = os.date("%H:%M")

  local new_lines = vim.deepcopy(existing)
  if #new_lines == 0 or new_lines[#new_lines] ~= "" then
    table.insert(new_lines, "")
  end
  table.insert(new_lines, "## " .. hhmm)
  table.insert(new_lines, "")
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(new_lines, line)
  end
  while #new_lines > 0 and new_lines[#new_lines] == "" do
    table.remove(new_lines)
  end
  table.insert(new_lines, "")

  vim.fn.writefile(new_lines, p)

  require("kb.todo").sync(p)

  return p
end

function M.open_today()
  local p = M.ensure()
  vim.cmd("edit " .. vim.fn.fnameescape(p))
  return p
end

return M
