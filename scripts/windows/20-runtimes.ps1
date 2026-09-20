# Language runtimes that winget does not fully cover: Node (fnm), pnpm, Rust,
# Python (uv), Maven and Composer. Versions match the other platforms.
# The JDKs and PHP themselves come from manifests/windows-packages.txt.
# Run with -DryRun to report without changing anything.
# Pass -InstallBuildTools to install the Visual Studio Build Tools (C++ workload)
# that Rust needs for linking; it is large and shows an elevation prompt.
[CmdletBinding()]
param([switch]$DryRun, [switch]$InstallBuildTools)

. "$PSScriptRoot\lib.ps1"
Update-SessionPath

$nodeMajor = 24
$pythonVersion = '3.14'
$mavenVersion = '3.9.16'

# --- Node (fnm) and pnpm ------------------------------------------------------
Write-Step "Node $nodeMajor via fnm"
if (-not (Test-Command fnm)) {
    Write-Warn 'fnm is not installed; run 10-packages.ps1 first'
} elseif ($DryRun) {
    Write-Warn 'skipping Node installation (dry run)'
} else {
    if (-not (fnm list | Select-String "v$nodeMajor\.")) { fnm install $nodeMajor }
    else { Write-Ok "Node $nodeMajor.x already installed" }
    fnm default $nodeMajor

    # fnm keeps a stable junction to the default version. Putting it on the User
    # PATH lets GUI programs (VS Code, IDEs) find Node without loading the PowerShell
    # profile. The per-shell fnm_multishells paths are never added.
    $fnmDir = (fnm env --json | ConvertFrom-Json).FNM_DIR
    Add-UserPath (Join-Path $fnmDir 'aliases\default')
    Update-SessionPath

    if (Test-Command corepack) {
        corepack enable
        corepack prepare pnpm@latest --activate
        Write-Ok "Node $(node --version), npm $(npm --version), pnpm $(pnpm --version)"
    } else {
        Write-Warn 'corepack not found; pnpm was not activated'
    }
}

# --- Rust ---------------------------------------------------------------------
Write-Step 'Rust (rustup, MSVC toolchain)'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$hasLinker = (Test-Path $vswhere) -and
    (& $vswhere -products * -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
if ($hasLinker) {
    Write-Ok 'MSVC C++ build tools present'
} elseif ($InstallBuildTools -and -not $DryRun) {
    Write-Step 'installing Visual Studio Build Tools (C++ workload)'
    winget install --id Microsoft.VisualStudio.BuildTools --exact --source winget `
        --accept-package-agreements --accept-source-agreements `
        --override '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
} else {
    Write-Warn 'MSVC C++ build tools are missing; Rust cannot link without them (re-run with -InstallBuildTools)'
}
if (-not (Test-Command rustup)) {
    Write-Warn 'rustup is not installed; run 10-packages.ps1 first'
} elseif ($DryRun) {
    Write-Warn 'skipping Rust toolchain installation (dry run)'
} elseif (Test-Command rustc) {
    Write-Ok (rustc --version)
} else {
    rustup default stable
}

# --- Python (uv) -------------------------------------------------------------
Write-Step "Python $pythonVersion via uv"
if (-not (Test-Command uv)) {
    Write-Warn 'uv is not installed; run 10-packages.ps1 first'
} elseif ($DryRun) {
    Write-Warn 'skipping Python installation (dry run)'
} else {
    # --default also places python.exe / python3.exe shims in ~/.local/bin.
    uv python install $pythonVersion --default --preview-features python-install-default
    Add-UserPath (Join-Path $HOME '.local\bin')
}

# --- Maven --------------------------------------------------------------------
Write-Step "Maven $mavenVersion"
$mavenHome = Join-Path $env:LOCALAPPDATA 'Programs\Maven'
if (Test-Command mvn) {
    Write-Ok ((mvn --version | Select-Object -First 1))
} elseif ($DryRun) {
    Write-Warn "would install Maven $mavenVersion to $mavenHome"
} else {
    $base = "https://archive.apache.org/dist/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"
    $hash = (Invoke-RestMethod "$base.sha512").Trim()
    $zip = Get-VerifiedDownload -Url $base -ExpectedHash $hash -Algorithm SHA512
    $staging = Join-Path ([IO.Path]::GetTempPath()) "maven-$mavenVersion"
    if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $staging
    New-Item -ItemType Directory -Force -Path (Split-Path $mavenHome) | Out-Null
    Move-Item -Path (Join-Path $staging "apache-maven-$mavenVersion") -Destination $mavenHome
    Remove-Item $staging, $zip -Recurse -Force
    Add-UserPath (Join-Path $mavenHome 'bin')
    Write-Ok "Maven $mavenVersion installed to $mavenHome"
}

# --- Composer -----------------------------------------------------------------
Write-Step 'Composer'
$composerHome = Join-Path $env:LOCALAPPDATA 'Programs\Composer'
if (Test-Command composer) {
    Write-Ok ((composer --version 2>&1 | Select-Object -First 1))
} elseif (-not (Test-Command php)) {
    Write-Warn 'php is not installed; run 10-packages.ps1 first'
} elseif ($DryRun) {
    Write-Warn "would install Composer to $composerHome"
} else {
    $base = 'https://getcomposer.org/download/latest-stable/composer.phar'
    $expected = ((Invoke-RestMethod "$base.sha256sum").Trim() -split '\s+')[0]
    $phar = Get-VerifiedDownload -Url $base -ExpectedHash $expected -Algorithm SHA256
    New-Item -ItemType Directory -Force -Path $composerHome | Out-Null
    Move-Item -Path $phar -Destination (Join-Path $composerHome 'composer.phar') -Force
    Set-Content -Path (Join-Path $composerHome 'composer.bat') -Encoding ascii -Value "@echo off`r`nphp `"%~dp0composer.phar`" %*"
    Add-UserPath $composerHome
    Write-Ok "Composer installed to $composerHome"
}

Write-Ok 'runtimes ready'
