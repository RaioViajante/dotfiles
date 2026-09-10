-- Language servers: install with Mason, configure with the native Neovim 0.11+
-- LSP API, and enable through mason-lspconfig.

return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonUpdate", "MasonInstall" },
    opts = {
      ui = { border = "rounded" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
    },
    config = function()
      require("mason").setup({ ui = { border = "rounded" } })

      -- Mason package names. Servers cover TypeScript / JavaScript / Angular,
      -- HTML / CSS / JSON, ESLint, PHP, Python, Java, Lua, Bash and YAML; the
      -- rest are the command-line formatters conform.nvim runs.
      require("mason-tool-installer").setup({
        ensure_installed = {
          "lua-language-server",
          "typescript-language-server",
          "angular-language-server",
          "html-lsp",
          "css-lsp",
          "json-lsp",
          "emmet-language-server",
          "eslint-lsp",
          "intelephense",
          "pyright",
          "ruff",
          "jdtls",
          "bash-language-server",
          "yaml-language-server",
          "stylua",
          "prettierd",
          "shfmt",
          "black",
          "isort",
        },
      })

      -- blink.cmp capabilities apply to every server through the "*" config.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Per-server overrides, keyed by lspconfig server name. Servers without an
      -- entry use the defaults nvim-lspconfig ships.
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              completion = { callSnippet = "Replace" },
              diagnostics = { globals = { "vim" } },
              telemetry = { enable = false },
            },
          },
        },
        eslint = {
          settings = { workingDirectories = { mode = "auto" } },
        },
        pyright = {
          settings = {
            -- ruff owns import sorting; pyright only does types.
            pyright = { disableOrganizeImports = true },
          },
        },
      }
      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
      end

      -- Enables every server Mason has installed and can map. Tools installed on
      -- the first launch start working after the next restart. stylua is a
      -- formatter (conform.nvim runs it); exclude its LSP shim.
      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_enable = {
          exclude = { "stylua" },
        },
      })

      -- Buffer-local keymaps once a server attaches. Neovim 0.11+ already binds
      -- grn / gra / grr / gri / gO; these add Telescope pickers and hints.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true }),
        callback = function(event)
          local function m(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          local builtin = require("telescope.builtin")
          m("grd", builtin.lsp_definitions, "Definitions")
          m("grt", builtin.lsp_type_definitions, "Type definitions")
          m("<leader>ds", builtin.lsp_document_symbols, "Document symbols")
          m("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            m("<leader>th", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, "Toggle inlay hints")
          end
        end,
      })

      local sign = vim.g.have_nerd_font and { ERROR = "", WARN = "", INFO = "", HINT = "" }
        or { ERROR = "E", WARN = "W", INFO = "I", HINT = "H" }
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = { severity = vim.diagnostic.severity.ERROR },
        virtual_text = { source = "if_many", spacing = 2 },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = sign.ERROR,
            [vim.diagnostic.severity.WARN] = sign.WARN,
            [vim.diagnostic.severity.INFO] = sign.INFO,
            [vim.diagnostic.severity.HINT] = sign.HINT,
          },
        },
      })
    end,
  },
}
