-- Bootstrap and configure lazy.nvim (the plugin manager).

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    os.exit(1)
  end
  -- Start from the commit pinned in lazy-lock.json. Otherwise the first
  -- install records the stable branch's commit in the lockfile and a restore
  -- keeps it.
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local ok, lock = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  end)
  local pinned = ok and lock["lazy.nvim"] and lock["lazy.nvim"].commit
  if pinned then
    vim.fn.system({ "git", "-C", lazypath, "checkout", "--quiet", pinned })
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { "catppuccin", "habamax" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  rocks = {
    -- No plugin here needs luarocks; skip the hererocks bootstrap entirely.
    enabled = false,
  },
  ui = {
    border = "rounded",
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Update the plugin lockfile and sync from the command line.
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Open Lazy" })
