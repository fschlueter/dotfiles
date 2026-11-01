-- Submit only comment `id` (other pending comments stay): send_all() reads comments.list()
-- once up front, so filter it for that call.
local function submit_one(id)
  local comments = require("herdr-nvim.comments")
  local list = comments.list
  comments.list = function()
    return vim.tbl_filter(function(c)
      return c.id == id
    end, list())
  end
  local ok, err = pcall(require("herdr-nvim").send_all, { submit = true })
  comments.list = list
  if not ok then
    error(err)
  end
end

-- One-shot: comment `span` and submit it to the agent on <CR>
local function comment_and_submit(span)
  local ui = require("herdr-nvim.ui")
  local bufnr = vim.api.nvim_get_current_buf()
  ui.input_comment(function(text)
    local id = require("herdr-nvim.comments").add(bufnr, span, text)
    ui.decorate(id)
    submit_one(id)
  end)
end

return {

  {
    "ChmaraX/herdr-nvim",
    opts = {},
    config = function(_, opts)
      require("herdr-nvim").setup(opts)
      vim.keymap.set("n", "<leader>aC", function()
        local l = vim.api.nvim_win_get_cursor(0)[1]
        comment_and_submit({ start_line = l, end_line = l })
      end, { desc = "herdr-nvim: comment line and send to agent" })
      vim.keymap.set("x", "<leader>aC", function()
        vim.cmd([[execute "normal! \<esc>"]]) -- materialize '< '> marks
        comment_and_submit(require("herdr-nvim.ui").visual_region())
      end, { desc = "herdr-nvim: comment selection and send to agent" })
    end,
  },
}
