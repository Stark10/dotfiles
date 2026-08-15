param()

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE"
    }
}

foreach ($Command in @("chezmoi", "mise", "pwsh", "rg", "task")) {
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "Validation requires '$Command'. Run the bootstrap first."
    }
}

$PowerShellFiles = @(
    "bootstrap.ps1",
    "packages/windows.ps1",
    "scripts/validate.ps1",
    "home/private_Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
)
foreach ($File in $PowerShellFiles) {
    $Tokens = $null
    $Errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $RepoRoot $File),
        [ref]$Tokens,
        [ref]$Errors
    )
    if ($Errors.Count -gt 0) {
        throw ($Errors | Format-List | Out-String)
    }
}

$JsonFiles = @(
    "home/private_dot_config/nvim/lazyvim.json",
    "home/private_dot_config/nvim/lazy-lock.json",
    "home/private_dot_config/nvim/dot_neoconf.json",
    "home/private_dot_config/oh-my-posh/dev.omp.json"
)
foreach ($File in $JsonFiles) {
    Get-Content (Join-Path $RepoRoot $File) -Raw | ConvertFrom-Json | Out-Null
}

$env:MISE_GLOBAL_CONFIG_FILE = Join-Path $RepoRoot "home/private_dot_config/mise/config.toml"
Invoke-Native "mise" @("config", "ls")
Push-Location $RepoRoot
try {
    Invoke-Native "task" @("--list")
} finally {
    Pop-Location
}

& rg -n --glob "!setup-macos.sh" --glob "!README.md" --glob "!SETUP.md" `
    --glob "!scripts/validate.sh" --glob "!scripts/validate.ps1" `
    "claudecode|claude-code" $RepoRoot
if ($LASTEXITCODE -eq 0) {
    throw "Active configuration still references Claude Code."
}
if ($LASTEXITCODE -gt 1) {
    throw "ripgrep failed with exit code $LASTEXITCODE"
}

$WindowsAlacritty = Get-Content (Join-Path $RepoRoot "home/AppData/Roaming/alacritty/alacritty.toml") -Raw
if ($WindowsAlacritty -notmatch 'decorations = "None"' -or $WindowsAlacritty -notmatch "opacity = 0.7") {
    throw "Managed Windows Alacritty settings are incorrect."
}
if (-not (Test-Path (Join-Path $RepoRoot "home/private_dot_config/nvim/lua/plugins/omp.lua") -PathType Leaf)) {
    throw "Managed OMP LazyVim integration is missing."
}

if ($IsWindows) {
    $TestHome = Join-Path ([System.IO.Path]::GetTempPath()) "stark10-dotfiles-validation-$([guid]::NewGuid())"
    $TestChezmoiHome = Join-Path $TestHome ".config/chezmoi"
    $TestChezmoiConfig = Join-Path $TestChezmoiHome "stark10-dotfiles.toml"
    try {
        New-Item -ItemType Directory -Path $TestChezmoiHome -Force | Out-Null
        @"
sourceDir = "/preserve/default/config"
[data]
marker = "preserve-me"
"@ | Set-Content (Join-Path $TestChezmoiHome "chezmoi.toml")

        Invoke-Native "chezmoi" @(
            "--config", $TestChezmoiConfig,
            "init", "--source", $RepoRoot,
            "--promptString", "Git author name=Validation User",
            "--promptString", "Git author email=validation@example.invalid"
        )
        Invoke-Native "chezmoi" @(
            "--config", $TestChezmoiConfig,
            "apply", "--source", $RepoRoot,
            "--destination", $TestHome
        )

        if ((Get-Content (Join-Path $TestChezmoiHome "chezmoi.toml") -Raw) -notmatch "preserve-me") {
            throw "The default chezmoi config was modified."
        }
        $GitConfig = Get-Content (Join-Path $TestHome ".gitconfig") -Raw
        if ($GitConfig -notmatch "name = Validation User" -or $GitConfig -notmatch "email = validation@example.invalid") {
            throw "Rendered Git identity is incorrect."
        }
        $RenderedAlacritty = Get-Content (Join-Path $TestHome "AppData/Roaming/alacritty/alacritty.toml") -Raw
        if ($RenderedAlacritty -notmatch 'decorations = "None"' -or $RenderedAlacritty -notmatch "opacity = 0.7") {
            throw "Rendered Windows Alacritty settings are incorrect."
        }
        if (-not (Test-Path (Join-Path $TestHome ".config/nvim/lua/plugins/omp.lua") -PathType Leaf)) {
            throw "Rendered OMP LazyVim integration is missing."
        }
    } finally {
        if (Test-Path $TestHome) {
            Remove-Item $TestHome -Recurse -Force
        }
    }
}

$Bootstrap = Join-Path $RepoRoot "bootstrap.ps1"
& $Bootstrap -DryRun | Out-Null
$SkipDryRun = & $Bootstrap -DryRun -SkipDotfiles
if ($SkipDryRun -match "nvim --headless") {
    throw "The skip-dotfiles dry run still attempts to sync Neovim."
}
Write-Host "Validation passed."
