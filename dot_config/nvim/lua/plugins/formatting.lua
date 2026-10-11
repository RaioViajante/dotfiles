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

-- Black reads [tool.black] from the nearest pyproject.toml.
local function black_configured(dir)
  local pyproject = vim.fs.find("pyproject.toml", { path = dir, upward = true })[1]
  return pyproject ~= nil and file_contains(pyproject, "\n%[tool%.black%]")
end

-- isort uses the first directory upward with an isort section in one of its
-- config files.
local function isort_configured(dir)
  local sections = {
    [".isort.cfg"] = { "" },
    ["pyproject.toml"] = { "\n%[tool%.isort%]" },
    ["setup.cfg"] = { "\n%[isort%]", "\n%[tool:isort%]" },
    ["tox.ini"] = { "\n%[isort%]", "\n%[tool:isort%]" },
  }
  return vim.fs.root(dir, function(name, path)
    for _, pattern in ipairs(sections[name] or {}) do
      if file_contains(vim.fs.joinpath(path, name), pattern) then
        return true
      end
    end
    return false
  end) ~= nil
end

-- Python formatters follow explicit project configuration only, never installed
-- dependencies: Black (after isort when isort is configured) where Black is
-- configured, isort alone where only isort is, and Ruff otherwise (Ruff reads
-- its own ruff.toml / [tool.ruff] settings, or uses its defaults). Black and
-- Ruff never run together.
local function python_formatters(bufnr)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  local black, isort = black_configured(dir), isort_configured(dir)
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
