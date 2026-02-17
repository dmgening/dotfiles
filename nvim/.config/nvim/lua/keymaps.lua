local map = vim.keymap.set

-- Clear search highlight on Escape
map("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Buffer navigation (carried from old vim config)
map("n", "gb", ":bnext<CR>", { silent = true })
map("n", "gB", ":bprev<CR>", { silent = true })
map("n", "<leader>d", ":confirm bdelete<CR>", { silent = true })
map("n", "<leader>w", ":confirm write<CR>", { silent = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { silent = true })
map("n", "<C-j>", "<C-w>j", { silent = true })
map("n", "<C-k>", "<C-w>k", { silent = true })
map("n", "<C-l>", "<C-w>l", { silent = true })

-- Show/hide hidden chars (carried from old vim config)
map("n", "<leader>eh", ":set list!<CR>", { silent = true })

-- Diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic list" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
