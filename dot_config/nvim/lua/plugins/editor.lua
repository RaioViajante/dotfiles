-- Smaller quality-of-life plugins.

return {
  -- Popup that lists the keybindings following the one you started.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "document" },
        { "<leader>f", group = "find / file" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "git hunk" },
        { "<leader>t", group = "toggle" },
        { "<leader>w", group = "write / workspace" },
      },
    },
  },

  -- Status line. Icons off to match the terminal font.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "catppuccin",
        icons_enabled = false,
        component_separators = "|",
        section_separators = "",
        globalstatus = true,
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "diagnostics", "encoding", "fileformat", "filetype" },
      },
    },
  },

  -- Auto-insert matching brackets and quotes.
  { "echasnovski/mini.pairs", version = false, event = "InsertEnter", opts = {} },

  -- Extra text objects: around/inside function, argument, tag, and more.
  {
    "echasnovski/mini.ai",
    version = false,
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ a = { "@block.outer", "@conditional.outer", "@loop.outer" }, i = { "@block.inner", "@conditional.inner", "@loop.inner" } }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        },
      }
    end,
  },

  -- Indentation guides.
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "|" },
      scope = { enabled = true, show_start = false, show_end = false },
    },
  },

  -- Highlight and search TODO / FIXME / NOTE comments.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Find TODO comments" },
    },
  },
}
