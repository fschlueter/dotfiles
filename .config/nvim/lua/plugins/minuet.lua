-- lua/plugins/minuet.lua
local kiconnect_key
local function get_kiconnect_key()
  if not kiconnect_key then
    kiconnect_key = vim.trim(vim.fn.system({
      "security", "find-generic-password", "-s", "campus-ki", "-w",
    }))
  end
  return kiconnect_key
end

return {
  "milanglacier/minuet-ai.nvim",
  cond = function()
    return require("config.dotfiles").ai("minuet")
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "InsertEnter",
  opts = {
    provider = "openai_compatible",
    request_timeout = 5,
    n_completions = 1,
    context_window = 8000,
    -- No auto suggestions while editing inside a word
    enable_predicates = {
      function()
        return not require("config.util").cursor_before_word()
      end,
    },
    virtualtext = {
      auto_trigger_ft = { "python", "cpp", "c", "lua", "sh" },
      -- Copilot-style keys; accept-all is <Tab> (via LazyVim's ai_accept in config below)
      keymap = {
        accept_line = "<A-a>",
        next = "<A-]>",
        prev = "<A-[>",
        dismiss = "<C-]>",
      },
    },
    provider_options = {
      openai_compatible = {
        name = "KIconnect",
        end_point = "https://chat.kiconnect.nrw/api/v1/chat/completions",
        api_key = get_kiconnect_key,
        model = "OpenAI GPT OSS 120B",
        stream = true,
        optional = {
          max_tokens = 256,
          reasoning_effort = "low",
        },
      },
    },
  },
  config = function(_, opts)
    require("minuet").setup(opts)
    -- <Tab> (blink keymap from LazyVim) accepts a visible suggestion, else jumps snippets / indents
    LazyVim.cmp.actions.ai_accept = function()
      local vt = require("minuet.virtualtext").action
      if vt.is_visible() then
        LazyVim.create_undo()
        vt.accept()
        return true
      end
    end
  end,
}
