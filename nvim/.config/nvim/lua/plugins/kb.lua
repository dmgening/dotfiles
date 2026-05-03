return {
  -- Test-only dependency for plenary.busted. Loaded directly by the test
  -- harness via rtp prepend; lazy in normal nvim sessions.
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
}
