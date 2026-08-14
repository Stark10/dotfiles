param(
    [switch]$DryRun,
    [switch]$SkipPackages,
    [switch]$SkipTools,
    [switch]$SkipDotfiles,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

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

if (-not $SkipPackages) {
    & (Join-Path $RepoRoot "packages/windows.ps1") -DryRun:$DryRun
}

$env:PATH = "$env:LOCALAPPDATA\Microsoft\WinGet\Links;$env:PATH"
$XdgConfigHome = Join-Path $HOME ".config"
$MiseConfig = Join-Path $XdgConfigHome "mise/config.toml"
$ChezmoiConfigHome = Join-Path $XdgConfigHome "chezmoi"
$ChezmoiConfig = Join-Path $ChezmoiConfigHome "stark10-dotfiles.toml"

if ($DryRun) {
    Write-Host "[dry-run] use XDG_CONFIG_HOME=$XdgConfigHome for this process"
    Write-Host "[dry-run] use MISE_GLOBAL_CONFIG_FILE=$MiseConfig for this process"
}
$env:XDG_CONFIG_HOME = $XdgConfigHome
$env:MISE_GLOBAL_CONFIG_FILE = $MiseConfig
$env:DOTFILES_NVIM_BOOTSTRAP = Join-Path $RepoRoot "scripts/wait-for-mason.lua"
$DotfilesApplied = $false

$Chezmoi = Get-Command chezmoi -ErrorAction SilentlyContinue
$Mise = Get-Command mise -ErrorAction SilentlyContinue

if (-not $Chezmoi -and -not $DryRun) {
    throw "chezmoi was not found after package installation. Restart PowerShell and rerun bootstrap.ps1."
}
if (-not $Mise -and -not $DryRun) {
    throw "mise was not found after package installation. Restart PowerShell and rerun bootstrap.ps1."
}

if (-not $SkipDotfiles) {
    if ($DryRun) {
        if (Test-Path $ChezmoiConfig -PathType Leaf) {
            Write-Host "[dry-run] refresh isolated chezmoi config at $ChezmoiConfig"
        } else {
            Write-Host "[dry-run] generate isolated chezmoi config at $ChezmoiConfig"
        }
        Write-Host "[dry-run] chezmoi --config $ChezmoiConfig diff --source $RepoRoot"
        Write-Host "[dry-run] chezmoi --config $ChezmoiConfig apply --source $RepoRoot"
    } else {
        $ActiveChezmoiConfig = Join-Path ([System.IO.Path]::GetTempPath()) "stark10-dotfiles-$([guid]::NewGuid()).toml"
        if (Test-Path $ChezmoiConfig -PathType Leaf) {
            Copy-Item $ChezmoiConfig $ActiveChezmoiConfig
        }
        try {
            Invoke-Native "chezmoi" @("--config", $ActiveChezmoiConfig, "init", "--source", $RepoRoot)
            Invoke-Native "chezmoi" @("--config", $ActiveChezmoiConfig, "diff", "--source", $RepoRoot)
            if (-not $Yes) {
                $Reply = Read-Host "Apply the dotfile changes above? [y/N]"
                if ($Reply -notmatch "^[Yy]$") {
                    $SkipDotfiles = $true
                    Write-Host "Dotfile application skipped."
                }
            }
            if (-not $SkipDotfiles) {
                Invoke-Native "chezmoi" @("--config", $ActiveChezmoiConfig, "apply", "--source", $RepoRoot)
                New-Item -ItemType Directory -Path $ChezmoiConfigHome -Force | Out-Null
                Copy-Item $ActiveChezmoiConfig $ChezmoiConfig -Force
                $DotfilesApplied = $true
            }
        } finally {
            if (Test-Path $ActiveChezmoiConfig -PathType Leaf) {
                Remove-Item $ActiveChezmoiConfig -Force
            }
        }
    }
}

if ($DryRun -and -not $SkipDotfiles) {
    Write-Host "[dry-run] persist XDG_CONFIG_HOME and MISE_GLOBAL_CONFIG_FILE after a successful apply"
} elseif ($DotfilesApplied) {
    [Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $XdgConfigHome, "User")
    [Environment]::SetEnvironmentVariable("MISE_GLOBAL_CONFIG_FILE", $MiseConfig, "User")
}

if (-not $SkipTools) {
    if ($DryRun) {
        Write-Host "[dry-run] mise --yes install"
        Write-Host "[dry-run] mise exec -- nvim --headless '+Lazy! restore' +qa"
        Write-Host "[dry-run] mise exec -- nvim --headless '+lua dofile(vim.env.DOTFILES_NVIM_BOOTSTRAP)'"
    } else {
        Invoke-Native "mise" @("--yes", "install")
        Invoke-Native "mise" @("exec", "--", "nvim", "--headless", "+Lazy! restore", "+qa")
        Invoke-Native "mise" @("exec", "--", "nvim", "--headless", "+lua dofile(vim.env.DOTFILES_NVIM_BOOTSTRAP)")
    }
}

if ($DryRun) {
    Write-Host "[dry-run] git lfs install"
} elseif (Get-Command git-lfs -ErrorAction SilentlyContinue) {
    git lfs install | Out-Null
}

Write-Host "Bootstrap complete. Restart PowerShell, then run: mise doctor"
