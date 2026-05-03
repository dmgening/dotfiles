-- Minimal init for plenary test harness
-- Loads only plenary + LuaSnip; no other plugins, no user config.

local data = vim.fn.stdpath("data")
local plenary_path = data .. "/lazy/plenary.nvim"
local luasnip_path = data .. "/lazy/LuaSnip"

if vim.fn.isdirectory(plenary_path) == 0 then
  error("plenary.nvim not found at " .. plenary_path .. ". Run :Lazy sync first.")
end
if vim.fn.isdirectory(luasnip_path) == 0 then
  error("LuaSnip not found at " .. luasnip_path .. ". Run :Lazy sync first.")
end

vim.opt.rtp:prepend(plenary_path)
vim.opt.rtp:prepend(luasnip_path)

vim.opt.rtp:prepend(vim.fn.fnamemodify(vim.fn.expand("<sfile>:p:h"), ":h:h"))

-- Source plenary's plugin file so PlenaryBustedDirectory is available.
-- PlenaryBustedFile is redefined here to run the spec in-process
-- (via plenary.busted.run) rather than spawning a subprocess, so that
-- the rtp already set up in this init (including LuaSnip) is inherited.
vim.cmd("runtime plugin/plenary.vim")

vim.api.nvim_create_user_command("PlenaryBustedFile", function(args)
  local path = require("plenary.path"):new(args.args)
  require("plenary.busted").run(path:absolute())
end, { nargs = 1, complete = "file" })

require("plenary.busted")
