# Install the curated VS Code extensions from manifests/vscode-extensions.txt.
# Only missing extensions are installed. Settings Sync and sign-in are never touched.
# Run with -DryRun to report without changing anything.
[CmdletBinding()]
param([switch]$DryRun)

. "$PSScriptRoot\lib.ps1"
Update-SessionPath

if (-not (Test-Command code)) { throw "'code' is not on PATH; run 10-packages.ps1 first (Microsoft.VisualStudioCode)." }

Write-Step 'VS Code extensions (manifests/vscode-extensions.txt)'
$installed = @(code --list-extensions | ForEach-Object { $_.ToLowerInvariant() })
$failures = 0
foreach ($ext in Get-ManifestEntry 'vscode-extensions.txt') {
    if ($installed -contains $ext.ToLowerInvariant()) { Write-Ok $ext; continue }
    if ($DryRun) { Write-Warn "would install $ext"; continue }
    Write-Step "installing $ext"
    code --install-extension $ext --force *> $null
    if ($LASTEXITCODE -ne 0) { Write-Warn "failed to install $ext"; $failures++ }
}
if ($failures) { throw "$failures extension(s) failed to install; re-run this script or check the ids" }
Write-Ok 'VS Code extensions ready'
