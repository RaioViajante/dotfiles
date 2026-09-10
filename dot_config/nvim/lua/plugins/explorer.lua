-- File explorer (neo-tree).

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<leader>fe", "<cmd>Neotree toggle reveal<CR>", desc = "Explorer (file tree)" },
    { "<leader>ge", "<cmd>Neotree git_status<CR>", desc = "Explorer (git status)" },
  },
  opts = {
    enable_git_status = true,
    enable_diagnostics = true,
    close_if_last_window = true,
    default_component_configs = {
      icon = {
        folder_closed = "+",
        folder_open = "-",
        folder_empty = "*",
        default = " ",
      },
      git_status = {
        symbols = {
          added = "A",
          modified = "M",
          deleted = "D",
          renamed = "R",
          untracked = "?",
          ignored = "I",
          unstaged = "U",
          staged = "S",
          conflict = "C",
        },
      },
    },
    window = {
      width = 34,
      mappings = {
        ["<space>"] = "none",
        ["P"] = { "toggle_preview", config = { use_float = true } },
      },
    },
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_by_name = { ".git", ".DS_Store", "node_modules" },
      },
    },
  },
}
