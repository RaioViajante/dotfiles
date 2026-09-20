# Install the packages listed in manifests/windows-packages.txt with winget.
# Only missing packages are installed; everything else is reported as present.
# Run with -DryRun to see what would be installed without changing anything.
[CmdletBinding()]
param([switch]$DryRun)

. "$PSScriptRoot\lib.ps1"

# winget must already exist (App Installer ships with Windows 11).
if (-not (Test-Command winget)) { throw 'winget is not available; update "App Installer" from the Microsoft Store.' }

# Per-package installer options. Docker Desktop is installed per user with the
# WSL 2 backend: no Hyper-V, no Windows containers.
$customArgs = @{
    'Docker.DockerDesktop' = '--user --accept-license --backend=wsl-2 --quiet'
}

# Packages that may already be present without winget knowing about them.
$presenceChecks = @{
    'DEVCOM.JetBrainsMonoNerdFont' = {
        [bool](Get-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction Ignore |
            Get-Member -MemberType NoteProperty | Where-Object Name -Like 'JetBrainsMono Nerd Font*')
    }
}

function Test-Installed([string]$Id) {
    if ($presenceChecks.ContainsKey($Id) -and (& $presenceChecks[$Id])) { return $true }
    winget list --id $Id --exact --accept-source-agreements *> $null
    $LASTEXITCODE -eq 0
}

Write-Step 'winget packages (manifests/windows-packages.txt)'
$failures = @()
foreach ($entry in Get-ManifestEntry 'windows-packages.txt') {
    $source = 'winget'
    $id = $entry
    if ($entry -match '^msstore:(.+)$') { $source = 'msstore'; $id = $Matches[1] }

    if (Test-Installed $id) { Write-Ok $id; continue }
    if ($DryRun) { Write-Warn "would install $id"; continue }

    Write-Step "installing $id"
    $arguments = @('install', '--id', $id, '--exact', '--source', $source,
        '--accept-package-agreements', '--accept-source-agreements')
    if ($customArgs.ContainsKey($id)) { $arguments += @('--custom', $customArgs[$id]) }
    winget @arguments
    if ($LASTEXITCODE -ne 0) { Write-Warn "failed to install $id (exit $LASTEXITCODE)"; $failures += $id }
}

Update-SessionPath
if ($failures) { throw "$($failures.Count) package(s) failed: $($failures -join ', ')" }
Write-Ok 'packages ready'
