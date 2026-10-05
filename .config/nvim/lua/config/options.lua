-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.o.exrc = true
vim.g.trouble_lualine = false
vim.opt.relativenumber = false

-- Block in normal/visual, bar in insert, underline in replace; normal and insert blink
vim.opt.guicursor =
  "n-v-c:block-Cursor-blinkon500-blinkoff500,i-ci-ve:ver25-iCursor-blinkon500-blinkoff500,r-cr-o:hor20-Cursor"

vim.g.autoformat = false -- LazyVim: no format on save (toggle per buffer with <leader>uf)

vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})
-- Save on focus loss so external tools (e.g. Claude Code) see current content; no ! to keep the conflict warning
vim.api.nvim_create_autocmd("FocusLost", {
  command = "silent! wa",
})
