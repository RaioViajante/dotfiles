-- Formatting on save (conform.nvim). Formatters are installed by Mason in
-- lua/plugins/lsp.lua.

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = function(bufnr)
      -- Let the LSP handle indentation for languages without a dedicated
      -- formatter here.
      local no_lsp_fallback = { c = true, cpp = true }
      return {
        timeout_ms = 1000,
        lsp_format = no_lsp_fallback[vim.bo[bufnr].filetype] and "never" or "fallback",
      }
    end,
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      css = { "prettierd" },
      scss = { "prettierd" },
      html = { "prettierd" },
      json = { "prettierd" },
      jsonc = { "prettierd" },
      yaml = { "prettierd" },
      markdown = { "prettierd" },
      sh = { "shfmt" },
      bash = { "shfmt" },
    },
  },
}
