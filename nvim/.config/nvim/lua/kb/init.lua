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

  vim.api.nvim_create_user_command("KbFind", function()
    require("kb.find").files()
  end, { desc = "Find files in vault (with in-picker scope swap)" })

  vim.api.nvim_create_user_command("KbGrep", function()
    require("kb.find").grep()
  end, { desc = "Live grep over the vault (with in-picker scope swap)" })

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
  map("<leader>kt", "<cmd>KbTodo<cr>", "Todo")
  map("<leader>kD", "<cmd>KbToday<cr>", "Today's daily")
  -- <leader>kd reserved for Phase 2 dashboard
  map("<leader>kf", "<cmd>KbFind<cr>", "Find files")
  map("<leader>kg", "<cmd>KbGrep<cr>", "Grep vault")

  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>k", group = "kb" },
    })
  end
end

local function in_vault(filepath)
  if not filepath or filepath == "" then return false end
  local config = require("kb.config")
  local vault = config.vault()
  return vim.startswith(vim.fn.fnamemodify(filepath, ":p"), vault)
end

local function define_autocmds()
  local config = require("kb.config")
  local group = vim.api.nvim_create_augroup("KbHarness", { clear = true })

  -- Sync tasks from daily to todo.md whenever a daily file is saved.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = config.vault() .. "/daily/*.md",
    callback = function(args)
      require("kb.todo").sync(args.file)
    end,
  })

  -- Buffer-local gd/gr in vault files: jump to @-mention / show backlinks.
  -- NOTE: gd/gr are buffer-local. If you later attach a markdown LSP
  -- (e.g., marksman, ltex), it may set its own gd/gr mappings via LspAttach.
  -- The order is: kb's BufEnter fires first, LspAttach fires later, so LSP wins
  -- — that's usually what you want. Override here if not.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
    group = group,
    callback = function(args)
      if not in_vault(args.file) then return end
      vim.keymap.set("n", "gd", function()
        require("kb.at").jump()
      end, { buffer = args.buf, desc = "kb: jump to @-mention" })
      vim.keymap.set("n", "gr", function()
        require("kb.at").backlinks()
      end, { buffer = args.buf, desc = "kb: backlinks for @-mention" })
    end,
  })
end

function M.setup()
  define_commands()
  define_keymaps()
  define_autocmds()
end

return M
