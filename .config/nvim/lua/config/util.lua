local M = {}

-- True if the (insert-mode) cursor sits directly before a keyword character, i.e. inside or at the start of a word.
function M.cursor_before_word()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local next_char = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
  return next_char ~= "" and vim.fn.match(next_char, [[\k]]) == 0
end

return M
