return {
  "saghen/blink.cmp",
  opts = {
    -- Off in markdown. Comments only suppress the menu (auto_show below): an enabled() that is
    -- false at a buffer's first insert keeps blink from ever setting up that buffer's keymaps.
    enabled = function()
      return vim.bo.filetype ~= "markdown"
    end,
    -- Enter is a plain newline; accept with <C-y> (LazyVim's <Tab> still jumps snippets / accepts AI text)
    keymap = {
      preset = "default",
    },
    completion = {
      menu = {
        -- Don't pop up inside comments or while editing inside a word (<C-space> still opens it)
        auto_show = function()
          local util = require("config.util")
          return not util.cursor_in_comment() and not util.cursor_before_word()
        end,
      },
    },
  },
}
