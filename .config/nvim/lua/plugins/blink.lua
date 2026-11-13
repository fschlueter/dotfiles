return {
  "saghen/blink.cmp",
  opts = {
    -- Off in markdown and inside comments (checked on every trigger)
    enabled = function()
      return vim.bo.filetype ~= "markdown" and not require("config.util").cursor_in_comment()
    end,
    -- Enter is a plain newline; accept with <C-y> (LazyVim's <Tab> still jumps snippets / accepts AI text)
    keymap = {
      preset = "default",
    },
    completion = {
      menu = {
        -- Don't pop up while editing inside a word (<C-space> still opens it)
        auto_show = function()
          return not require("config.util").cursor_before_word()
        end,
      },
    },
  },
}
