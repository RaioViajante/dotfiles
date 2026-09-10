-- Catppuccin Mocha, to match the VS Code theme and the iTerm2 profile.

return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "mocha",
    background = { dark = "mocha" },
    transparent_background = false,
    term_colors = true,
    integrations = {
      cmp = true,
      gitsigns = true,
      neotree = true,
      telescope = true,
      treesitter = true,
      which_key = true,
      native_lsp = {
        enabled = true,
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
