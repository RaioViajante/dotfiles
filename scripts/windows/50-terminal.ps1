# Windows Terminal baseline: PowerShell 7 as the default profile, JetBrainsMono
# Nerd Font, and the home directory as the starting directory. Nothing else
# (colours, keybindings, tabs, opacity) is touched, and the settings file is not
# versioned because Windows Terminal rewrites it. The previous file is backed up.
# Run with -DryRun to report without changing anything.
[CmdletBinding()]
param([switch]$DryRun)

. "$PSScriptRoot\lib.ps1"

$settingsPath = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal*\LocalState\settings.json') -ErrorAction Ignore |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $settingsPath) {
    Write-Warn 'Windows Terminal has no settings file yet; open it once, then re-run this step'
    return
}

Write-Step 'Windows Terminal baseline'
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable

# PowerShell 7 registers itself under a fixed source name; use the GUID Terminal generated for it.
$pwsh = $settings.profiles.list |
    Where-Object { $_.ContainsKey('source') -and $_.source -eq 'Windows.Terminal.PowershellCore' } |
    Select-Object -First 1
if (-not $pwsh) { Write-Warn 'PowerShell 7 profile not found in Windows Terminal; is Microsoft.PowerShell installed?'; return }

if (-not $settings.profiles.ContainsKey('defaults')) { $settings.profiles.defaults = @{} }
$defaults = $settings.profiles.defaults
if (-not $defaults.ContainsKey('font')) { $defaults.font = @{} }

$changes = @()
if ($settings.defaultProfile -ne $pwsh.guid) { $settings.defaultProfile = $pwsh.guid; $changes += 'default profile' }
if ($defaults.font.face -ne 'JetBrainsMono Nerd Font') { $defaults.font.face = 'JetBrainsMono Nerd Font'; $changes += 'font' }
if ($defaults.startingDirectory -ne '%USERPROFILE%') { $defaults.startingDirectory = '%USERPROFILE%'; $changes += 'starting directory' }

if (-not $changes) { Write-Ok 'already configured'; return }
if ($DryRun) { Write-Warn "would change: $($changes -join ', ')"; return }

Copy-Item $settingsPath "$settingsPath.bak" -Force
$settings | ConvertTo-Json -Depth 20 | Set-Content $settingsPath -Encoding utf8NoBOM
Write-Ok "updated: $($changes -join ', ') (backup: settings.json.bak)"
