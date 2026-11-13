return {
  "saghen/blink.cmp",
  opts = {
    -- Off in markdown and inside comments (checked on every trigger)
    enabled = function()
      return vim.bo.filetype ~= "markdown" and not require("config.util").cursor_in_comment()
    end,
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
