-- Formatting (conform.nvim). Project configuration decides: Prettier only runs
-- where the project configures it, and Python uses whichever of Ruff or
-- Black/isort the project configures. Formatters come from Mason
-- (lua/plugins/lsp.lua) unless the project provides its own copy.

-- Filetypes Prettier owns. Without a Prettier config they are not formatted
-- on save at all, rather than falling back to a language server's style.
local prettier_fts = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "css",
  "scss",
  "html",
  "json",
  "jsonc",
  "yaml",
  "markdown",
}

-- True when the file exists and matches the Lua pattern; a leading "\n" in the
-- pattern also matches the first line.
local function file_contains(path, pattern)
  local f = io.open(path, "r")
  if not f then
    return false
  end
  local text = "\n" .. f:read("*a")
  f:close()
  return text:find(pattern) ~= nil
end

-- conform's prettierd root resolver covers the Prettier config files and the
-- "prettier" key in package.json; Prettier also reads that key from package.yaml.
local function prettier_root(self, ctx)
  return require("conform.formatters.prettierd").cwd(self, ctx)
    or vim.fs.root(ctx.dirname, function(name, path)
      return name == "package.yaml" and file_contains(vim.fs.joinpath(path, name), "\nprettier%s*:")
    end)
end

-- Pick Python formatters from the nearest project configuration: Black (with
-- isort when configured) where the project configures Black, isort alone where
-- only isort is configured, and Ruff otherwise. Never Black and Ruff together.
local function python_formatters(bufnr)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  local root = vim.fs.root(dir, { "pyproject.toml", "ruff.toml", ".ruff.toml", "setup.cfg", "tox.ini", ".isort.cfg" })
  local function has(file, pattern)
    return root ~= nil and file_contains(vim.fs.joinpath(root, file), pattern)
  end
  local black = has("pyproject.toml", "%[tool%.black%]")
  local isort = has("pyproject.toml", "%[tool%.isort%]")
    or (root ~= nil and vim.uv.fs_stat(vim.fs.joinpath(root, ".isort.cfg")) ~= nil)
    or has("setup.cfg", "%[isort%]")
    or has("tox.ini", "%[isort%]")
  if black then
    return isort and { "isort", "black" } or { "black" }
  elseif isort then
    return { "isort" }
  end
  return { "ruff_organize_imports", "ruff_format" }
end

-- Prefer a tool from the project's virtual environment over Mason's copy.
local function venv_tool(name)
  return require("conform.util").find_executable({ ".venv/bin/" .. name }, name)
end

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
  opts = function()
    local by_ft = {
      lua = { "stylua" },
      python = python_formatters,
      sh = { "shfmt" },
      bash = { "shfmt" },
    }
    for _, ft in ipairs(prettier_fts) do
      by_ft[ft] = { "prettierd" }
    end

    return {
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        -- Prettier and Python formatting follow the project configuration only;
        -- other languages may fall back to their language server.
        local project_owned = ft == "python" or vim.list_contains(prettier_fts, ft)
        -- Let the LSP handle indentation for languages without a dedicated
        -- formatter here.
        local no_lsp_fallback = { c = true, cpp = true }
        -- 3 s leaves room for Python formatters on the first save after opening
        -- a file, while language servers are still starting.
        return {
          timeout_ms = 3000,
          lsp_format = (project_owned or no_lsp_fallback[ft]) and "never" or "fallback",
        }
      end,
      formatters_by_ft = by_ft,
      formatters = {
        prettierd = { cwd = prettier_root, require_cwd = true },
        ruff_format = { command = venv_tool("ruff") },
        ruff_organize_imports = { command = venv_tool("ruff") },
        black = { command = venv_tool("black") },
        isort = { command = venv_tool("isort") },
      },
    }
  end,
}
