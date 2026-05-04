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

  vim.api.nvim_create_user_command("KbReindex", function()
    require("kb.index").refresh()
    vim.notify("[kb] index refreshed", vim.log.levels.INFO)
  end, { desc = "Rebuild kb entity + tag index" })

  vim.api.nvim_create_user_command("KbTaskSync", function(args)
    local path
    if args.args ~= "" then
      path = vim.fn.fnamemodify(args.args, ":p")
    else
      path = vim.api.nvim_buf_get_name(0)
      local daily_prefix = require("kb.config").vault() .. "/daily/"
      local is_daily = path ~= "" and vim.startswith(vim.fn.resolve(path), vim.fn.resolve(daily_prefix))
      if not is_daily then
        vim.notify("[kb] KbTaskSync: current buffer is not a daily file", vim.log.levels.WARN)
        return
      end
    end
    local synced = require("kb.todo").sync(path)
    if synced then
      vim.notify("[kb] task sync: merged tasks", vim.log.levels.INFO)
    else
      vim.notify("[kb] task sync: nothing to merge", vim.log.levels.INFO)
    end
  end, { nargs = "?", complete = "file", desc = "Re-sync tasks from a daily into todo.md" })
end

local function define_keymaps()
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end

  map("<leader>kc", "<cmd>KbCapture<cr>", "Capture")
  map("<leader>kt", "<cmd>KbTodo<cr>", "Todo")
  map("<leader>kD", "<cmd>KbToday<cr>", "Today's daily")
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

  -- Save-time refresh of the entity + tag index.
  -- Match all *.md and check vault membership in the callback (more robust
  -- than vault-rooted glob, which can fail when args.file is a tilde path
  -- or differs from the vault by a normalization).
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(args)
      local abs = vim.fn.fnamemodify(args.file, ":p")
      if not vim.startswith(abs, config.vault() .. "/") then return end
      require("kb.index").refresh_file(abs)
    end,
  })

  -- Buffer-local gd/gr in vault files: jump to @-mention or markdown link / show backlinks.
  -- nowait=true so they fire immediately without waiting on the global
  -- LSP-default longer prefixes (gra/gri/grn/grr in nvim 0.11+, plus gD).
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
      end, { buffer = args.buf, nowait = true, desc = "kb: jump to @-mention or link" })
      vim.keymap.set("n", "gr", function()
        require("kb.at").backlinks()
      end, { buffer = args.buf, nowait = true, desc = "kb: backlinks for @-mention or #tag" })

      -- Image-paste interception in vault markdown buffers.
      if vim.bo[args.buf].filetype == "markdown" then
        for _, key in ipairs({ "p", "P" }) do
          vim.keymap.set("n", key, function()
            require("kb.images").paste_or_fallthrough(key)
          end, { buffer = args.buf, desc = "kb: paste image or default paste" })
        end
        vim.keymap.set("i", "<C-r>+", function()
          require("kb.images").paste_or_fallthrough("<C-r>+")
        end, { buffer = args.buf, desc = "kb: paste image (insert mode) or default" })
      end
    end,
  })

  -- Attach kb + luasnip cmp sources to vault buffers (and buffers flagged via b:kb_in_vault).
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      local in_vault_path = in_vault(args.file)
      local flagged = vim.b[args.buf].kb_in_vault == 1
      if not (in_vault_path or flagged) then return end
      local ok, cmp = pcall(require, "cmp")
      if not ok then return end
      cmp.setup.buffer({
        sources = cmp.config.sources({
          { name = "kb" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  })

  -- Engage the modal todo buffer when todo.md is opened.
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = group,
    pattern = config.vault() .. "/todo.md",
    callback = function(args)
      require("kb.todo_modal").attach(args.buf)
    end,
  })

  -- Image-paste lifecycle: migrate referenced tmps to vault/images on save,
  -- sweep unreferenced tmps on save, sweep all pending tmps on unload/exit.
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = config.vault() .. "/**/*.md",
    callback = function(args)
      require("kb.images").on_buf_write_pre(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufUnload", {
    group = group,
    callback = function(args)
      if package.loaded["kb.images"] then
        require("kb.images").on_buf_unload(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if package.loaded["kb.images"] then
        require("kb.images").cleanup_all()
      end
    end,
  })
end

function M.setup()
  define_commands()
  define_keymaps()
  define_autocmds()
end

return M
