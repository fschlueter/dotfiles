-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Cursor colors derived from the active theme (accent as block, background as text)
local function set_cursor_hl()
  local function get(name, attr)
    return vim.api.nvim_get_hl(0, { name = name, link = false })[attr]
  end
  local text = get("Normal", "bg") or 0x000000
  local block = get("Function", "fg") or get("Special", "fg") or get("Normal", "fg") or 0xc1ff8a
  vim.api.nvim_set_hl(0, "Cursor", { fg = text, bg = block, bold = true })
  vim.api.nvim_set_hl(0, "iCursor", { fg = text, bg = block })
end
set_cursor_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_cursor_hl })

-- mini.diff overlay: old (reference) text of changed lines in red instead of DiffText (blue);
-- the new buffer text then needs its own group, as it links to MiniDiffOverChange by default
local function set_minidiff_hl()
  local function get(name, attr)
    return vim.api.nvim_get_hl(0, { name = name, link = false })[attr]
  end
  local red = get("Red", "fg") or get("DiagnosticError", "fg") or 0xe67e80
  local green = get("Green", "fg") or get("DiagnosticOk", "fg") or 0xa7c080
  vim.api.nvim_set_hl(0, "MiniDiffOverChange", { fg = get("Normal", "bg"), bg = red, bold = true })
  vim.api.nvim_set_hl(0, "MiniDiffOverContext", { link = "DiffDelete" })
  vim.api.nvim_set_hl(0, "MiniDiffOverChangeBuf", { fg = get("Normal", "bg"), bg = green, bold = true })
end
set_minidiff_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_minidiff_hl })
