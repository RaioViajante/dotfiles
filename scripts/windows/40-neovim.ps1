# Restore the Neovim plugin state after `chezmoi apply` has written
# %LOCALAPPDATA%\nvim: lazy.nvim plugins, Tree-sitter parsers and Mason tools.
# None of this state is committed; it is rebuilt here. Safe to re-run.
# Run with -DryRun to report without changing anything.
[CmdletBinding()]
param([switch]$DryRun)

. "$PSScriptRoot\lib.ps1"
Update-SessionPath

if (-not (Test-Command nvim)) { throw 'nvim is not installed; run 10-packages.ps1 first.' }
$config = Join-Path $env:LOCALAPPDATA 'nvim'
if (-not (Test-Path (Join-Path $config 'init.lua'))) {
    Write-Warn "no Neovim config in $config yet; run 'chezmoi apply' and then re-run this step"
    return
}
if ($DryRun) { Write-Warn 'dry run: Neovim plugins, parsers and Mason tools were not touched'; return }

$dataDir = (nvim --headless -u NONE '+lua io.write(vim.fn.stdpath("data"))' +qa 2>&1 | Out-String).Trim()

# --- lazy.nvim plugins: restore the versions pinned in lazy-lock.json ---------------
Write-Step 'lazy.nvim plugins'
nvim --headless '+Lazy! restore' +qa 2>&1 | Out-Null
Write-Ok 'plugins restored'

# --- Tree-sitter parsers ----------------------------------------------------------
# Parsers are compiled with Zig (no Visual Studio developer environment needed).
# They are installed one at a time and with the config bypassed (-u NONE): the
# config's own ensure_installed starts every build at once, and concurrent cold-cache
# Zig invocations deadlock.
Write-Step 'Tree-sitter parsers'
if (-not (Test-Command zig)) {
    Write-Warn 'zig is not on PATH; parsers cannot be compiled (winget package zig.zig)'
} else {
    $treesitter = Join-Path $dataDir 'lazy\nvim-treesitter'
    $parserDir = Join-Path $treesitter 'parser'
    $languages = nvim --headless -u NONE `
        "+lua io.write(table.concat(dofile(vim.fn.stdpath('config') .. '/lua/plugins/treesitter.lua').opts.ensure_installed, ' '))" `
        +qa 2>&1 | Out-String
    foreach ($language in ($languages.Trim() -split '\s+')) {
        if (Test-Path (Join-Path $parserDir "$language.so")) { Write-Ok $language; continue }
        Write-Step "compiling $language"
        nvim -u NONE --headless --cmd "set rtp+=$treesitter" '+runtime plugin/nvim-treesitter.lua' `
            "+TSInstallSync $language" +qa 2>&1 | Out-Null
        if (Test-Path (Join-Path $parserDir "$language.so")) { Write-Ok $language }
        else { Write-Warn "parser $language did not build" }
    }
}

# --- Mason tools (language servers and formatters) --------------------------------
# Several packages are npm-based, so Node must be reachable.
Write-Step 'Mason tools'
if (-not (Test-Command node)) {
    Write-Warn 'node is not on PATH; run 20-runtimes.ps1 first'
} else {
    $trigger = Join-Path ([IO.Path]::GetTempPath()) 'mason-trigger.lua'
    Set-Content -Path $trigger -Value '-- opens a Lua buffer so the LSP config loads'
    $log = Join-Path ([IO.Path]::GetTempPath()) 'mason.log'
    nvim --headless $trigger '+sleep 2' '+MasonToolsInstallSync' "+redir! > $log | silent messages | redir END" +qa 2>&1 | Out-Null
    $failed = @(Get-Content $log -ErrorAction Ignore | Where-Object { $_ -match 'failed to install' } | Sort-Object -Unique)
    Remove-Item $trigger, $log -Force -ErrorAction Ignore
    if ($failed) { $failed | ForEach-Object { Write-Warn $_ } } else { Write-Ok 'Mason tools installed' }
}

Write-Ok 'Neovim ready (optional :checkhealth warnings about the Python provider, tree-sitter CLI and vim.pack are expected)'
