return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = { hidden = true, watch = true },
          files = { hidden = true },
        },
      },
      notifier = { timeout = 10000 }, -- ms, default is 3000
    },
  },
}
