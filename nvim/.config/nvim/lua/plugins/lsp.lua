return {
  -- LSP server installer
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {},
  },

  -- Bridge between mason and lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "pyright",
        "gopls",
        "ts_ls",
        "bashls",
        "dockerls",
        "lua_ls",
      },
      automatic_installation = true,
    },
  },

  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      -- LspAttach: buffer-local keymaps + native completion
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local bufnr = ev.buf
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
          end

          map("gd", vim.lsp.buf.definition,     "Go to definition")
          map("gD", vim.lsp.buf.declaration,    "Go to declaration")
          map("gr", vim.lsp.buf.references,     "References")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("K",  vim.lsp.buf.hover,          "Hover docs")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>rn", vim.lsp.buf.rename,      "Rename")

          -- Enable native LSP completion (nvim 0.11+)
          if client and vim.lsp.completion then
            vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
          end
        end,
      })

      -- Server setup
      lspconfig.pyright.setup({})
      lspconfig.gopls.setup({})
      lspconfig.ts_ls.setup({})
      lspconfig.bashls.setup({})
      lspconfig.dockerls.setup({})
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
          },
        },
      })
    end,
  },

  -- Formatter (manual trigger only)
  {
    "stevearc/conform.nvim",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      format_on_save = false,
      formatters_by_ft = {
        python     = { "ruff_format" },
        go         = { "goimports" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact  = { "prettierd" },
        javascriptreact  = { "prettierd" },
        json       = { "prettierd" },
        yaml       = { "prettierd" },
        markdown   = { "prettierd" },
        sh         = { "shfmt" },
        bash       = { "shfmt" },
        lua        = { "stylua" },
      },
    },
  },
}
