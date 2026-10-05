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
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "InsertEnter",
  opts = {
    provider = "openai_compatible",
    request_timeout = 5,
    n_completions = 1,
    context_window = 8000,
    virtualtext = {
      auto_trigger_ft = { "python", "cpp", "c", "lua", "sh" },
      keymap = {
        accept = "<A-A>",
        accept_line = "<A-a>",
        next = "<A-]>",
        prev = "<A-[>",
        dismiss = "<A-e>",
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
}
