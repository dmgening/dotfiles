local config = require("kb.config")

local M = {}

local function fzf()
  return require("fzf-lua")
end

function M.axis(name)
  fzf().files({ cwd = config.axis(name) })
end

function M.grep()
  fzf().live_grep({ cwd = config.vault() })
end

return M
