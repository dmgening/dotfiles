local augroup = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Auto-resize splits when terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Highlight trailing whitespace
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  callback = function()
    vim.fn.matchadd("Error", [[\s\+$]])
  end,
})
