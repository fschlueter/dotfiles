-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr><cmd>ClaudeCodeFocus<cr>', { desc = 'Send to Claude and focus' })
vim.keymap.set('v', '<leader>aS', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send to Claude' })
