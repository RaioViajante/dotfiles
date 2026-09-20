#Requires -Version 7.0
<#
.SYNOPSIS
    One-time Windows workstation bootstrap. Safe to re-run.

.DESCRIPTION
    Run it from PowerShell 7 in a normal (non-elevated) session; installers that
    need elevation show their own prompt. Steps run in order:

      10  winget packages          (manifests/windows-packages.txt)
      20  language runtimes        (Node, pnpm, Rust, Python, Maven, Composer)
      30  VS Code extensions       (manifests/vscode-extensions.txt)
      40  Neovim plugin state      (needs `chezmoi apply` first)
      50  Windows Terminal baseline

    Recommended order on a clean machine: bootstrap, `chezmoi apply`, bootstrap again
    (the second pass completes step 40 and every step reports "ok" for the rest).

.PARAMETER Only
    Run a single step by its number prefix, for example -Only 40.

.PARAMETER DryRun
    Report what would change without changing anything.

.PARAMETER InstallBuildTools
    Also install the Visual Studio Build Tools (C++ workload) that Rust needs.
#>
[CmdletBinding()]
param(
    [string]$Only,
    [switch]$DryRun,
    [switch]$InstallBuildTools
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib.ps1"

if ($env:OS -ne 'Windows_NT') { throw 'this bootstrap targets Windows' }
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'do not run this script elevated; installers request elevation themselves'
}

$steps = '10-packages.ps1', '20-runtimes.ps1', '30-vscode-extensions.ps1', '40-neovim.ps1', '50-terminal.ps1'
foreach ($step in $steps) {
    if ($Only -and -not $step.StartsWith($Only)) { continue }
    Write-Host "`n########## $step ##########" -ForegroundColor Cyan
    $arguments = @{ DryRun = $DryRun }
    if ($step -eq '20-runtimes.ps1') { $arguments.InstallBuildTools = $InstallBuildTools }
    & (Join-Path $PSScriptRoot $step) @arguments
}

@'

########## bootstrap complete ##########

Manual steps that this bootstrap deliberately does not perform:
  - WSL 2 + Ubuntu:      wsl --install -d Ubuntu-24.04      (elevated; may need a reboot)
  - Docker Desktop:      start it once, accept the terms, then enable Ubuntu under
                         Settings -> Resources -> WSL Integration (never sign in to Docker Hub
                         unless you want to; keep "start at login" off)
  - GitHub sign-in:      gh auth login --hostname github.com --web --git-protocol ssh
  - SSH key for GitHub:  ssh-keygen -t ed25519 -a 100 -f "$HOME\.ssh\id_ed25519_github"
                         gh ssh-key add "$HOME\.ssh\id_ed25519_github.pub"
  - Git identity:        git config --file "$HOME\.config\git\local.gitconfig" user.name  "..."
                         git config --file "$HOME\.config\git\local.gitconfig" user.email "..."
  - Application sign-ins: Proton, Discord, Spotify, JetBrains, Postman, Notion, Claude, ChatGPT
  - VS Code Settings Sync: not enabled; the dotfiles are the source of truth
'@ | Write-Host
