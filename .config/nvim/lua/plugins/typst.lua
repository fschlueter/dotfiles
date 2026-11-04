-- Typst: on top of the LazyVim extra lang.typst (enabled in lazyvim.json).
-- Tinymist writes the PDF next to the main file on every save; open it once in Skim
-- (Preferences > Sync > "Check for file changes") and it reloads by itself.
-- When editing theme files, pin the talk first: <leader>cP in the talk's buffer.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tinymist = {
          settings = {
            exportPdf = "onSave",
          },
        },
      },
    },
  },
}
