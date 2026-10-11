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

-- The iTerm2 profile uses JetBrainsMono Nerd Font Mono (Brewfile), so plugins
-- draw file-type and diagnostic glyphs. Set to false for a plain font.
vim.g.have_nerd_font = true

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
