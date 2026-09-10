-- Syntax-aware highlighting, indentation and text objects.

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  branch = "master",
  main = "nvim-treesitter.configs",
  init = function()
    -- jsonc has no standalone parser on the master branch; the json parser
    -- highlights it (comments included).
    vim.treesitter.language.register("json", "jsonc")
  end,
  opts = {
    ensure_installed = {
      "bash",
      "c",
      "css",
      "diff",
      "dockerfile",
      "gitcommit",
      "gitignore",
      "html",
      "java",
      "javascript",
      "jsdoc",
      "json",
      "lua",
      "luadoc",
      "markdown",
      "markdown_inline",
      "php",
      "python",
      "query",
      "regex",
      "scss",
      "sql",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "xml",
      "yaml",
    },
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
  },
}
