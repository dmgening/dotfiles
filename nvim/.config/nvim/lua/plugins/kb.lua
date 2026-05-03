return {
  -- Keybinding hint tree for <leader>k
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
    },
  },

  -- Test-only dependency. Lazy-loaded so it doesn't impact runtime.
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
}
