-- Minimal init for plenary test harness
-- Loads only plenary; no other plugins, no user config.

local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
  error("plenary.nvim not found at " .. plenary_path .. ". Run :Lazy sync first.")
end
vim.opt.rtp:prepend(plenary_path)

-- Make our lua/ available to require("kb.*")
vim.opt.rtp:prepend(vim.fn.fnamemodify(vim.fn.expand("<sfile>:p:h"), ":h:h"))

require("plenary.busted")

-- Define PlenaryBustedFile to run tests in-process (avoids rtp reset in child nvim).
-- The default plugin/plenary.vim definition spawns a child nvim that inherits
-- the user's init.lua, which overwrites the rtp set above.
vim.api.nvim_create_user_command("PlenaryBustedFile", function(o)
  require("plenary.busted").run(o.args)
end, { nargs = 1, complete = "file" })
