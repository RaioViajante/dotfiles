-- Completion, snippets and signature help (blink.cmp).

return {
  "saghen/blink.cmp",
  version = "1.*",
  event = "InsertEnter",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    -- <C-space> opens the menu, <C-y> accepts, <C-e> cancels, <Tab> jumps
    -- through snippet placeholders.
    keymap = { preset = "default" },
    appearance = {
      nerd_font_variant = "mono",
    },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 250 },
      menu = {
        draw = { treesitter = { "lsp" } },
      },
      ghost_text = { enabled = true },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    signature = { enabled = true },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
