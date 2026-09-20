# Shared helpers for the Windows bootstrap scripts. Dot-source this file; do not
# execute it. All output is English.

Set-StrictMode -Version Latest

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Write-Step([string]$Message) { Write-Host "==> $Message" -ForegroundColor Blue }
function Write-Ok([string]$Message)   { Write-Host "  ok $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "  !! $Message" -ForegroundColor Yellow }

function Test-Command([string]$Name) {
    [bool](Get-Command $Name -ErrorAction Ignore)
}

# Rebuild the session PATH from the registry so tools installed earlier in the
# same run (winget, Maven, fnm's default alias) become visible.
function Update-SessionPath {
    $env:Path = (@('Machine', 'User') | ForEach-Object { [Environment]::GetEnvironmentVariable('Path', $_) }) -join ';'
}

# Append a directory to the USER Path if it is missing. The registry value is
# edited in place so an existing REG_EXPAND_SZ entry keeps its %VARIABLES%.
function Add-UserPath([string]$Directory, [switch]$DryRun) {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    try {
        $current = [string]$key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
        $normalized = $Directory.TrimEnd('\')
        $present = $current -split ';' | Where-Object { $_ } |
            Where-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') -ieq $normalized }
        if ($present) { Write-Ok "User PATH already has $Directory"; return }
        if ($DryRun) { Write-Warn "would add to User PATH: $Directory"; return }
        $key.SetValue('Path', ($current.TrimEnd(';') + ';' + $Directory), 'ExpandString')
        # Setting any user variable broadcasts WM_SETTINGCHANGE so new processes see the change.
        [Environment]::SetEnvironmentVariable('DOTFILES_PATH_TOUCH', $null, 'User')
        Write-Ok "added to User PATH: $Directory"
    } finally { $key.Dispose() }
    Update-SessionPath
}

# Read a manifest under manifests/: one entry per line, '#' comments and blank lines ignored.
function Get-ManifestEntry([string]$Name) {
    $path = Join-Path $script:RepoRoot "manifests\$Name"
    if (-not (Test-Path $path)) { throw "manifest not found: $path" }
    Get-Content $path | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }
}

# Download a file over HTTPS and verify its SHA-256 or SHA-512 before returning its path.
function Get-VerifiedDownload([string]$Url, [string]$ExpectedHash, [ValidateSet('SHA256', 'SHA512')][string]$Algorithm) {
    $target = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetFileName($Url))
    Invoke-WebRequest -Uri $Url -OutFile $target -UseBasicParsing
    $actual = (Get-FileHash -Path $target -Algorithm $Algorithm).Hash
    if ($actual -ne $ExpectedHash.Trim().ToUpperInvariant()) {
        Remove-Item $target -Force
        throw "$Algorithm mismatch for $Url"
    }
    $target
}
