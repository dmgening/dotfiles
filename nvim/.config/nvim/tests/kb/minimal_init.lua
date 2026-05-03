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
