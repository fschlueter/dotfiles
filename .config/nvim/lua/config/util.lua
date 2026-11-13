local M = {}

-- True if the (insert-mode) cursor sits directly before a keyword character, i.e. inside or at the start of a word.
function M.cursor_before_word()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local next_char = vim.api.nvim_get_current_line():sub(col + 1, col + 1)
  return next_char ~= "" and vim.fn.match(next_char, [[\k]]) == 0
end

-- True if the character before the (insert-mode) cursor is highlighted as a comment by treesitter.
function M.cursor_in_comment()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, row - 1, math.max(col - 1, 0))
  if not ok then
    return false
  end
  for _, c in ipairs(captures) do
    if c.capture:match("^comment") then
      return true
    end
  end
  return false
end

return M
