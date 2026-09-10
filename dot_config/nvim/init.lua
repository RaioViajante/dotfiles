-- Neovim configuration entry point, managed by chezmoi (dotfiles).
--
-- Layout:
--   lua/config/   editor behaviour that needs no plugins
--   lua/plugins/  one file per concern, auto-imported by lazy.nvim
--
-- Bootstrapping: the first launch clones lazy.nvim and installs every plugin,
-- then pins the exact versions in lazy-lock.json (committed to the repo).

-- Leader keys must be set before lazy loads so plugin mappings register.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- The terminal font (Monaco) is not a Nerd Font, so plugins fall back to ASCII.
-- Install a Nerd Font and set this to true for file-type and git glyphs.
vim.g.have_nerd_font = false

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
