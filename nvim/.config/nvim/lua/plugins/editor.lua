return {
  -- Fuzzy finder (files, grep, buffers)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", function() require("fzf-lua").files() end,      desc = "Find files" },
      { "<C-p>",      function() require("fzf-lua").files() end,      desc = "Find files" },
      { "<leader>fg", function() require("fzf-lua").live_grep() end,  desc = "Live grep" },
      { "<leader>fb", function() require("fzf-lua").buffers() end,    desc = "Buffers" },
      { "<leader>fh", function() require("fzf-lua").help_tags() end,  desc = "Help" },
      { "<leader>fr", function() require("fzf-lua").oldfiles() end,   desc = "Recent files" },
    },
    opts = {},
  },

  -- File browser (edit filesystem as buffer)
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", function() require("oil").open() end, desc = "File browser" },
      { "-",         function() require("oil").open() end, desc = "File browser" },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },

  -- Git signs in gutter + inline blame
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
    keys = {
      { "]h", function() require("gitsigns").next_hunk() end,    desc = "Next hunk" },
      { "[h", function() require("gitsigns").prev_hunk() end,    desc = "Prev hunk" },
      { "<leader>hs", function() require("gitsigns").stage_hunk() end,   desc = "Stage hunk" },
      { "<leader>hr", function() require("gitsigns").reset_hunk() end,   desc = "Reset hunk" },
      { "<leader>hp", function() require("gitsigns").preview_hunk() end, desc = "Preview hunk" },
      { "<leader>hb", function() require("gitsigns").blame_line({ full = true }) end, desc = "Blame line" },
    },
  },

  -- Comments (gcc / gc)
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Surround (ys, cs, ds)
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Auto-close pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },
}
