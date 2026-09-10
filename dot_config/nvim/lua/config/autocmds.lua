-- Autocommands.

local function augroup(name)
  return vim.api.nvim_create_augroup("dotfiles_" .. name, { clear = true })
end

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Trim trailing whitespace on save (matches the dotfiles CI check). Skips
-- special buffers and filetypes where trailing spaces are meaningful.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim_whitespace"),
  callback = function(event)
    local skip = { markdown = true, diff = true }
    if vim.bo[event.buf].buftype ~= "" or skip[vim.bo[event.buf].filetype] then
      return
    end
    local view = vim.fn.winsaveview()
    pcall(function()
      vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
    end)
    vim.fn.winrestview(view)
  end,
})

-- Return to the last edit position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_position"),
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local line_count = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Language-specific indentation. Web and config files use 2 spaces; the JVM and
-- systems languages use 4.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_width"),
  pattern = { "python", "java", "kotlin", "groovy", "go", "rust", "php", "sh", "bash" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
  end,
})

-- Makefiles need real tabs.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("makefile_tabs"),
  pattern = "make",
  callback = function()
    vim.bo.expandtab = false
  end,
})

-- Close throwaway buffers with q.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("quick_close"),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "notify" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})
