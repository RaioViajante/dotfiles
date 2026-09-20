# PowerShell 7 profile (Windows). Managed by chezmoi.
#
# Native port of the shared zsh setup (aliases.zsh, functions.zsh, tools.zsh,
# dev.zsh). Every optional CLI is guarded, so a missing tool never breaks
# startup. Safe to dot-source repeatedly.

function Test-Cmd([string]$Name) {
    [bool](Get-Command $Name -CommandType Application -ErrorAction Ignore)
}

# --- Environment --------------------------------------------------------------
$env:EDITOR = $env:VISUAL = if (Test-Cmd code) { 'code --wait' } elseif (Test-Cmd nvim) { 'nvim' } else { 'notepad' }
$env:LESS = '-FRX'
$env:FZF_DEFAULT_OPTS = '--height=40% --layout=reverse --border'
if (-not $env:PROJECTS_DIR) { $env:PROJECTS_DIR = Join-Path $HOME 'Developer' }

# --- Tool integrations (same order and flags as tools.zsh / integrations.zsh) --
if (Test-Cmd fnm)      { fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression }
if (Test-Cmd zoxide)   { zoxide init powershell --cmd z | Out-String | Invoke-Expression }   # z / zi; cd is untouched
if (Test-Cmd starship) { Invoke-Expression (& starship init powershell) }

if (Get-Command Set-PSReadLineOption -ErrorAction Ignore) {
    Set-PSReadLineOption -HistoryNoDuplicates -MaximumHistoryCount 100000
}

# --- Navigation and files ------------------------------------------------------
# Functions cannot override built-in aliases, so drop the three that collide
# with the git shortcuts below (gc = Get-Content, gp = Get-ItemProperty, gl = Get-Location).
Remove-Item Alias:gc, Alias:gp, Alias:gl -Force -ErrorAction Ignore

function ..  { Set-Location .. }
function ... { Set-Location ../.. }
function c   { Clear-Host }
if (Test-Cmd eza) {
    function l    { eza --group-directories-first @args }
    function ll   { eza -lah --group-directories-first --git @args }
    function la   { eza -laa --group-directories-first --git @args }
    function lt   { eza --tree --level=2 --group-directories-first @args }
    function tree { eza --tree --group-directories-first @args }
}
if (Test-Cmd bat) {
    function bcat { bat --paging=never @args }
    function batp { bat --paging=always @args }
}
if (Test-Cmd nvim) {
    function vi      { nvim @args }
    function vim     { nvim @args }
    function vimdiff { nvim -d @args }
}

# --- Git, pnpm, Docker ---------------------------------------------------------
function g  { git @args }
function gs { git st @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git lg @args }

function p  { pnpm @args }
function pi { pnpm install @args }
function pd { pnpm dev @args }
function pb { pnpm build @args }
function pt { pnpm test @args }

function d   { docker @args }
function dc  { docker compose @args }
function dps { docker ps @args }

# --- Helpers -------------------------------------------------------------------
function mkcd([Parameter(Mandatory)][string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

function groot {
    $root = git rev-parse --show-toplevel 2>$null
    if ($root) { Set-Location $root }
}

function ports { Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress, LocalPort, OwningProcess, @{ n = 'Process'; e = { (Get-Process -Id $_.OwningProcess -ErrorAction Ignore).ProcessName } } }
function port([Parameter(Mandatory)][int]$Number) { ports | Where-Object LocalPort -eq $Number }
function psg([Parameter(Mandatory)][string]$Pattern) { Get-Process | Where-Object Name -Match $Pattern }
function myip { Invoke-RestMethod https://api.ipify.org }
function serve([int]$Port = 8000) { python -m http.server $Port }

# Windows ships bsdtar (libarchive): it reads tar, tar.gz/bz2/xz, zip and 7z. A
# bare .gz is handled with .NET. A bare .bz2 has no tool on a stock Windows.
function extract([Parameter(Mandatory)][string]$Archive) {
    if (-not (Test-Path -LiteralPath $Archive -PathType Leaf)) { Write-Error "usage: extract <archive>"; return }
    switch -Regex ($Archive) {
        '\.(tar\.(gz|bz2|xz)|tgz|tbz2|txz|tar|zip|7z)$' { tar -xf $Archive; return }
        '\.gz$' {
            $target = [IO.Path]::GetFileNameWithoutExtension($Archive)
            $in = [IO.File]::OpenRead((Resolve-Path -LiteralPath $Archive))
            try {
                $gz = [IO.Compression.GZipStream]::new($in, [IO.Compression.CompressionMode]::Decompress)
                $out = [IO.File]::Create((Join-Path $PWD $target))
                try { $gz.CopyTo($out) } finally { $out.Dispose(); $gz.Dispose() }
            } finally { $in.Dispose() }
            return
        }
        default { Write-Error "unsupported archive: $Archive"; return }
    }
}

function proj {
    if (-not ((Test-Cmd fzf) -and (Test-Cmd fd))) { Write-Warning 'proj needs fzf and fd'; return }
    $sel = fd --type d --hidden --no-ignore --max-depth 5 '^\.git$' $env:PROJECTS_DIR |
        ForEach-Object { [IO.Path]::GetDirectoryName($_.TrimEnd('\', '/')) } |
        fzf --prompt='project> '
    if ($sel) { Set-Location $sel }
}

# --- JDK switching -------------------------------------------------------------
# Temurin JDKs are installed by winget under Program Files; 25 is the machine
# default (JAVA_HOME / Machine PATH). `jdk 21` switches only the current session.
function jdk([string]$Version) {
    $root = Join-Path $env:ProgramFiles 'Eclipse Adoptium'
    $installed = Get-ChildItem $root -Directory -Filter 'jdk-*-hotspot' -ErrorAction Ignore |
        Sort-Object Name -Descending
    if (-not $Version) {
        "active: $(if ($env:JAVA_HOME) { $env:JAVA_HOME } else { 'none' })"
        java -version 2>&1 | Select-Object -First 1
        "`navailable:"
        $installed | ForEach-Object { '    ' + ($_.Name -replace '^jdk-(\d+).*', '$1') + '  ' + $_.FullName }
        return
    }
    $match = $installed | Where-Object Name -Like "jdk-$Version.*" | Select-Object -First 1
    if (-not $match) { Write-Error "JDK not found: $Version"; return }
    $adoptiumBin = [regex]::Escape($root) + '\\jdk-[^\\]+\\bin\\?$'
    $rest = $env:Path -split ';' | Where-Object { $_ -and $_ -notmatch $adoptiumBin }
    $env:JAVA_HOME = $match.FullName
    $env:Path = (@((Join-Path $match.FullName 'bin')) + $rest) -join ';'
    java -version 2>&1 | Select-Object -First 1
}
