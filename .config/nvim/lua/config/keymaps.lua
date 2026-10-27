-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+arrows: jump several words/lines (replaces LazyVim's window resize on these keys).
-- Ghostty sends Ctrl+Left/Right as <M-b>/<M-f> (esc:b/esc:f) for the shell.
local jumps = {
  { keys = { '<C-Left>', '<M-b>' }, motion = '5b', desc = 'Jump 5 words back' },
  { keys = { '<C-Right>', '<M-f>' }, motion = '5w', desc = 'Jump 5 words forward' },
  { keys = { '<C-Up>' }, motion = '5k', desc = 'Jump 5 lines up' },
  { keys = { '<C-Down>' }, motion = '5j', desc = 'Jump 5 lines down' },
}
for _, jump in ipairs(jumps) do
  for _, lhs in ipairs(jump.keys) do
    vim.keymap.set({ 'n', 'x', 'o' }, lhs, jump.motion, { desc = jump.desc })
    vim.keymap.set('i', lhs, '<C-o>' .. jump.motion, { desc = jump.desc })
  end
end

if require('config.dotfiles').ai('claudecode') then
  vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr><cmd>ClaudeCodeFocus<cr>', { desc = 'Send to Claude and focus' })
  vim.keymap.set('v', '<leader>aS', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send to Claude' })
end
