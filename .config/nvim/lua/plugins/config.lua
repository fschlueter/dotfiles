return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = { hidden = true, watch = true },
          files = { hidden = true },
          grep = { hidden = true },
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
              -- $ENVS_DIR/$DEFAULT_ENV from .env/env (defaults if nvim was not started from the dotfiles shell)
              -- pyright takes its search paths (incl. PYTHONPATH and the env's .pth files) from this interpreter
              pythonPath = vim.fn.expand((vim.env.ENVS_DIR or "~/software/envs") .. "/" .. (vim.env.DEFAULT_ENV or "py314") .. "/bin/python"),
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
