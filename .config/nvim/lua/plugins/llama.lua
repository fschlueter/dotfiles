--- The following is currently disabled
return {
  "ggml-org/llama.vim",
  enabled = false,
  init = function()
    vim.g.llama_config = {
      model_fim = "qwen-coder-3b-fim",
    }
  end,
}
