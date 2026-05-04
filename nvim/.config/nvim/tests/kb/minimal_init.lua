-- Minimal init for plenary test harness
-- Loads only plenary + LuaSnip; no other plugins, no user config.

local self_path = vim.fn.expand("<sfile>:p")

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

vim.opt.rtp:prepend(vim.fn.fnamemodify(self_path, ":h:h:h"))

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

-- Define PlenaryBustedFile to run tests in-process (avoids rtp reset in child nvim).
-- The default plugin/plenary.vim definition spawns a child nvim that inherits
-- the user's init.lua, which overwrites the rtp set above.
vim.api.nvim_create_user_command("PlenaryBustedFile", function(o)
  require("plenary.busted").run(o.args)
end, { nargs = 1, complete = "file" })

-- harness.test_directory spawns child nvim per spec via Job:new(--headless).
-- Children only inherit our rtp setup if they're launched with `-u minimal_init`.
-- Wrap test_directory to default opts.init to this file so callers don't have to.
do
  local harness = require("plenary.test_harness")
  local orig = harness.test_directory
  harness.test_directory = function(directory, opts)
    opts = opts or {}
    if opts.init == nil and opts.minimal_init == nil then
      opts.init = self_path
    end
    return orig(directory, opts)
  end
end
