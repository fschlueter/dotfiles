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
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            pyright = { disableOrganizeImports = true },
            -- python = { analysis = { ignore = { "*" } } }, -- uncomment to drop pyright diagnostics
            python = {
              pythonPath = vim.fn.expand("~/software/uvenvs/py314/bin/python"),
            },
          },
        },
        ruff = {
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },
}
