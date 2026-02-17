vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.shiftround = true

vim.opt.hidden = true
vim.opt.lazyredraw = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.laststatus = 2
vim.opt.showmode = false
vim.opt.backspace = "2"
vim.opt.wildmode = "list:longest,full"

vim.opt.wildignore:append({
  "*.sw?",
  "*.bak", "*.?~", "*.??~", "*.???~", "*.~",
  "*.luac",
  "*.jar",
  "*.pyc",
  "*.stats",
})

vim.opt.foldmethod = "marker"

vim.opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯЖ;ABCDEFGHIJKLMNOPQRSTUVWXYZ:,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"

local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
local result = handle:read("*a")
handle:close()
vim.o.background = result:match("Dark") and "dark" or "light"

vim.opt.listchars = { tab = "→ ", eol = "↵", trail = "·", extends = "↷", precedes = "↶" }
