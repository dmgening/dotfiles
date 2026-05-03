local M = {}

local function define_commands()
  vim.api.nvim_create_user_command("KbCapture", function()
    require("kb.capture").run()
  end, { desc = "Open kb capture floating window" })

  vim.api.nvim_create_user_command("KbToday", function()
    require("kb.daily").open_today()
  end, { desc = "Open today's daily file" })

  vim.api.nvim_create_user_command("KbTodo", function()
    require("kb.todo").open()
  end, { desc = "Open todo.md" })

  vim.api.nvim_create_user_command("KbFind", function(opts)
    local axis = opts.args
    if axis == "" then axis = "all" end
    require("kb.find").axis(axis)
  end, {
    desc = "Find files in vault (axis: people, projects, domains, all)",
    nargs = "?",
    complete = function() return { "people", "projects", "domains", "all" } end,
  })

  vim.api.nvim_create_user_command("KbGrep", function()
    require("kb.find").grep()
  end, { desc = "Live grep over the vault" })

  vim.api.nvim_create_user_command("KbAtJump", function()
    require("kb.at").jump()
  end, { desc = "Jump to file referenced by @-mention under cursor" })

  vim.api.nvim_create_user_command("KbAtBacklinks", function()
    require("kb.at").backlinks()
  end, { desc = "Show all references to @-mention under cursor" })
end

local function define_keymaps()
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end

  map("<leader>kc", "<cmd>KbCapture<cr>", "Capture")
  map("<leader>kt", "<cmd>KbToday<cr>", "Today's daily")
  map("<leader>kk", "<cmd>KbTodo<cr>", "Todo")
  map("<leader>kfp", "<cmd>KbFind people<cr>", "Find people")
  map("<leader>kfP", "<cmd>KbFind projects<cr>", "Find projects")
  map("<leader>kfd", "<cmd>KbFind domains<cr>", "Find domains")
  map("<leader>kfa", "<cmd>KbFind all<cr>", "Find all")
  map("<leader>kg", "<cmd>KbGrep<cr>", "Grep vault")
  map("<leader>kj", "<cmd>KbAtJump<cr>", "Jump to @-mention")
  map("<leader>kb", "<cmd>KbAtBacklinks<cr>", "Backlinks for @-mention")

  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>k",  group = "kb" },
      { "<leader>kf", group = "kb-find" },
    })
  end
end

local function define_autocmds()
  local config = require("kb.config")
  local group = vim.api.nvim_create_augroup("KbHarness", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = config.vault() .. "/daily/*.md",
    callback = function(args)
      require("kb.todo").sync(args.file)
    end,
  })
end

function M.setup()
  define_commands()
  define_keymaps()
  define_autocmds()
end

return M
