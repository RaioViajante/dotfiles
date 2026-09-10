-- Core editor options. Kept explicit; no hidden defaults from a framework.

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.termguicolors = true
opt.showmode = false
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "> ", trail = ".", nbsp = "+" }

-- Indentation: 2 spaces by default, overridden per language by an autocmd.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Files and undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400

-- Behaviour
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.confirm = true
opt.completeopt = { "menu", "menuone", "noselect" }

-- Keep the netrw banner off; neo-tree is the file explorer.
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- No plugin here uses the Perl, Ruby or Node RPC providers.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
