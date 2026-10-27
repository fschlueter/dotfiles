return {
  "saghen/blink.cmp",
  opts = {
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
