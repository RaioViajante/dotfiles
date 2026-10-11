# Neovim

The `nvim` configuration module installs Neovim and its dependencies and
applies the modular Lua configuration in `~/.config/nvim`.

## Included

- **Packages**: `neovim`, `fd`, `tree-sitter-cli` (`brew/nvim.Brewfile`), plus
  the shared `ripgrep`, `node@24` (Mason installs most servers with npm), the
  JetBrains Mono Nerd Font (icons) and `chezmoi`. A C compiler comes from the Command Line Tools.
- **Plugins** (pinned in `lazy-lock.json`): lazy.nvim, nvim-lspconfig, Mason
  with mason-lspconfig and mason-tool-installer, blink.cmp with
  friendly-snippets, conform.nvim, nvim-treesitter (`main` branch) and
  nvim-treesitter-textobjects, gitsigns, which-key, Telescope (fzf-native,
  ui-select), neo-tree, lualine, Catppuccin, nvim-web-devicons, mini.ai,
  mini.pairs, indent-blankline, todo-comments and fidget.
- **Appearance**: Catppuccin Mocha with Nerd Font icons
  (`vim.g.have_nerd_font = true` in `init.lua`; set it to `false` for a plain
  font).

## Install and apply

```sh
cd ~/.local/share/chezmoi
./setup nvim                    # packages and configuration
./setup --no-packages nvim      # configuration only
```

Then start `nvim` once. On a fresh install it clones lazy.nvim at the commit in
`lazy-lock.json`, installs the plugins at their locked commits, builds the
tree-sitter parsers and lets Mason install the language servers and
formatters. Restart Neovim once those finish so every server attaches.

## Languages

| Language | Highlighting | Language server | Formatting on save |
| --- | --- | --- | --- |
| TypeScript / JavaScript / React | tree-sitter | `ts_ls`, ESLint | Prettier when configured |
| Angular | tree-sitter (`angular` for templates) | `angularls`, only inside an Angular workspace (`angular.json` / `nx.json`) | Prettier when configured |
| HTML / CSS / Tailwind | tree-sitter | HTML, CSS, Emmet, Tailwind (projects with a Tailwind setup) | Prettier when configured |
| PHP | tree-sitter | Intelephense | language server |
| Laravel Blade | tree-sitter (`blade`) | none | none |
| Python | tree-sitter | Pyright, Ruff | Ruff, or Black / isort when configured |
| Java / Spring Boot | tree-sitter | jdtls | language server |
| Rust | tree-sitter | rust-analyzer from rustup ([dev module](development.md)) | rustfmt through rust-analyzer |
| Lua | tree-sitter | lua_ls | StyLua |
| Markdown | tree-sitter | Marksman | Prettier when configured |
| JSON / YAML | tree-sitter | jsonls, yamlls | Prettier when configured |
| Bash | tree-sitter | bashls | shfmt |

Parsers for other languages install automatically the first time you open
such a file.

## Formatting rules

conform.nvim formats on save (3 s limit) and with `<leader>cf`:

- **Prettier filetypes** (JS/TS, CSS, HTML, JSON, YAML, Markdown) are formatted
  only when the project configures Prettier: a Prettier config file
  (`.prettierrc*`, `prettier.config.*`) or a `prettier` key in `package.json` or
  `package.yaml`, searched upward from the file. Without one, saving does not
  reformat (no language-server fallback). prettierd uses the project's own
  installed Prettier version when there is one.
- **Python** follows explicit configuration only, never declared dependencies:
  Black where the nearest `pyproject.toml` has `[tool.black]` (after isort when
  isort is configured), isort alone where only isort is configured
  (`.isort.cfg`, `[tool.isort]`, `[isort]` / `[tool:isort]` in `setup.cfg` or
  `tox.ini`), and Ruff otherwise, which reads `ruff.toml` / `[tool.ruff]` or
  uses its defaults. Black and Ruff never run together. Tools in the project's
  `.venv/bin` win over Mason's copies.
- **Other filetypes** use their formatter, or the language server when there is
  none (C and C++ excepted).

## Tool ownership

| Tool | Owner |
| --- | --- |
| Neovim, fd, ripgrep, tree-sitter-cli, Node | Homebrew (this module and `brew/shared/`) |
| Language servers and formatters (except below) | Mason (`lua/plugins/lsp.lua`) |
| rust-analyzer, rustfmt | rustup ([dev module](development.md)) |
| Project formatter versions | the project (`node_modules`, `.venv`) |
| Plugins | lazy.nvim and `lazy-lock.json` |

## Updating plugins

Update deliberately and record the lockfile:

```vim
:Lazy update {plugin}
```

```sh
chezmoi re-add ~/.config/nvim/lazy-lock.json
```

Update specific plugins rather than everything at once; after updating
nvim-treesitter, `:TSUpdate` refreshes the parsers.

## Limitations

- Blade has highlighting only; there is no Blade language server here.
- Spring Boot support is jdtls' Java support; there is no Spring-specific
  integration. Debugging (nvim-dap) and nvim-jdtls are deferred.
- Tree-sitter indentation is experimental upstream; it is enabled only for
  languages that ship indent queries.
- No AI plugins are configured; AI agents run in the terminal.

## Troubleshooting

- Language servers missing after the first start: `:MasonToolsInstall`, then
  restart.
- Health report: `:checkhealth`, `:checkhealth nvim-treesitter`,
  `:ConformInfo`, `:LspInfo` (or `:checkhealth vim.lsp`).
- Parser build errors: check `tree-sitter --version` (0.26.1 or later) and the
  Command Line Tools.
- Icons show as boxes: the terminal is not using a Nerd Font; `./setup nvim`
  installs JetBrains Mono Nerd Font, select it in your terminal, or set
  `vim.g.have_nerd_font = false`.
