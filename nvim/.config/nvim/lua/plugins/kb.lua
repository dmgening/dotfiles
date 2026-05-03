return {
  -- Test-only dependency for plenary.busted. Loaded directly by the test
  -- harness via rtp prepend; lazy in normal nvim sessions.
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  -- Completion engine + baseline sources (Phase 1.5).
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter" },
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      require("kb.cmp").setup()
    end,
  },
}
