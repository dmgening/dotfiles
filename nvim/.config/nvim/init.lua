-- Set leader BEFORE lazy loads plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load modules
require("options")
require("keymaps")
require("autocmds")

-- Load plugins (auto-discovers lua/plugins/*.lua)
require("lazy").setup("plugins", {
  change_detection = { notify = false },
})
