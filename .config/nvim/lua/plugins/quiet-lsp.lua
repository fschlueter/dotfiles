-- ~/.config/nvim/lua/plugins/quiet-lsp.lua
-- Tones down LSP/linter noise in LazyVim (Python via the `lang.python` extra).

-- Shared overrides for pyright and basedpyright.
local overrides = {
  -- Missing imports (e.g. venv not picked up)
  reportMissingImports = "none",
  reportMissingModuleSource = "none",

  -- Optional: None/Optional and possibly-unbound warnings
  -- reportOptionalMemberAccess = "none",
  -- reportOptionalSubscript = "none",
  -- reportOptionalOperand = "none",
  -- reportPossiblyUnbound = "none",

  -- Optional: attribute/call errors on dynamic objects (also hides real typos!)
  -- reportAttributeAccessIssue = "none",
  -- reportCallIssue = "none",
  -- reportArgumentType = "none",
}

-- Optional (basedpyright only): unknown-type noise from untyped libraries
local basedpyright_extra = {
  -- reportUnknownMemberType = "none",
  -- reportUnknownVariableType = "none",
  -- reportUnknownArgumentType = "none",
  -- reportUnknownParameterType = "none",
  -- reportMissingParameterType = "none",
  -- reportAny = "none",
  -- reportUnusedCallResult = "none",
}

local analysis = {
  typeCheckingMode = "basic", -- or "off"
  diagnosticMode = "openFilesOnly",
  diagnosticSeverityOverrides = overrides,
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false }, -- <leader>uh toggles
      diagnostics = {
        update_in_insert = false,
        severity_sort = true,
        virtual_text = {
          severity = { min = vim.diagnostic.severity.ERROR },
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        underline = { severity = { min = vim.diagnostic.severity.WARN } },
        signs = { severity = { min = vim.diagnostic.severity.WARN } },
      },
      servers = {
        pyright = {
          settings = { python = { analysis = analysis } },
        },
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = vim.tbl_deep_extend("force", analysis, {
                diagnosticSeverityOverrides = basedpyright_extra,
              }),
            },
          },
        },
      },
    },
  },

  -- Don't run extra nvim-lint linters on top of the LSP.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = {},
        markdown = {},
      },
    },
  },
}
