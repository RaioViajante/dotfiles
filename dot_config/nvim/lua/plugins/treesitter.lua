-- Syntax-aware highlighting and indentation (nvim-treesitter, main branch).
-- The main branch needs Neovim 0.12+, tree-sitter-cli (Brewfile) and a C
-- compiler (Command Line Tools). Highlighting itself is Neovim's built-in
-- vim.treesitter; this plugin installs parsers and queries.

local parsers = {
  "angular",
  "bash",
  "blade",
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
  "rust",
  "scss",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

-- Start highlighting, and the experimental tree-sitter indentation where the
-- language ships indent queries.
local function attach(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
    return
  end
  if vim.treesitter.query.get(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  init = function()
    -- jsonc has no standalone parser; the json parser highlights it (comments included).
    vim.treesitter.language.register("json", "jsonc")
  end,
  config = function()
    local ts = require("nvim-treesitter")
    -- Asynchronous, and a no-op for parsers that are already installed.
    ts.install(parsers)

    local available = ts.get_available()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("dotfiles_treesitter", { clear = true }),
      callback = function(event)
        local buf, lang = event.buf, vim.treesitter.language.get_lang(event.match)
        if not lang then
          return
        end
        if vim.treesitter.language.add(lang) then
          attach(buf, lang)
        elseif vim.list_contains(available, lang) then
          -- Install a missing parser on first use, then attach to this buffer.
          ts.install(lang):await(function(err)
            if not err then
              vim.schedule(function()
                attach(buf, lang)
              end)
            end
          end)
        end
      end,
    })
  end,
}
