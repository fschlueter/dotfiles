-- Host profile flags exported by ~/.env/host (see .env/hosts/)
local M = {}

-- True if AI plugin `name` is enabled for this host. Without a profile (nvim not started from
-- the dotfiles shell) fall back to the OS: everything on macOS, nothing elsewhere.
-- (An empty DOTFILES_NVIM_AI reads as nil in nvim, hence the check on DOTFILES_PROFILE.)
function M.ai(name)
  if vim.env.DOTFILES_PROFILE == nil then
    return vim.fn.has("mac") == 1
  end
  local v = vim.env.DOTFILES_NVIM_AI or ""
  return vim.tbl_contains(vim.split(v, "%s+", { trimempty = true }), name)
end

return M
