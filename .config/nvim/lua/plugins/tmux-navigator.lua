-- Ctrl+h/j/k/l moves between nvim splits and, inside tmux, on into tmux panes
-- (tmux side: the same plugin in .tmux.conf). Outside tmux it only moves between splits.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to Left Window/Pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to Lower Window/Pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to Upper Window/Pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to Right Window/Pane" },
    },
  },
}
