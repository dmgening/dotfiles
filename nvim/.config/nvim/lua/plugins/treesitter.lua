return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "python", "go", "gomod", "gosum",
        "typescript", "javascript", "tsx",
        "bash", "lua", "json", "yaml", "toml",
        "markdown", "markdown_inline",
        "dockerfile", "make",
        "vim", "vimdoc",
        "html", "css",
      },
      highlight = { enable = true },
      indent   = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
