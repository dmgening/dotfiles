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

return M
