local map = vim.keymap.set

-- Clear search highlight on Escape
map("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Buffer navigation (carried from old vim config)
map("n", "gb", ":bnext<CR>", { silent = true, desc = "Next buffer" })
map("n", "gB", ":bprev<CR>", { silent = true, desc = "Prev buffer" })
map("n", "<leader>d", ":confirm bdelete<CR>", { silent = true, desc = "Delete buffer" })
map("n", "<leader>w", ":confirm write<CR>", { silent = true, desc = "Save file" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { silent = true, desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { silent = true, desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { silent = true, desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { silent = true, desc = "Window right" })

-- Show/hide hidden chars (carried from old vim config)
map("n", "<leader>eh", ":set list!<CR>", { silent = true, desc = "Toggle hidden chars" })
vim.opt.listchars = { tab = "→ ", eol = "↵", trail = "·", extends = "↷", precedes = "↶" }

-- Diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic list" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
