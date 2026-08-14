param([switch]$DryRun)

$ErrorActionPreference = "Stop"

if (-not $DryRun -and -not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required. Install Microsoft App Installer, then rerun this script."
}

$Packages = @(
    "Git.Git",
    "GitHub.GitLFS",
    "JanDeDobbeleer.OhMyPosh",
    "Microsoft.PowerShell",
    "Microsoft.WindowsTerminal",
    "Alacritty.Alacritty",
    "jdx.mise",
    "twpayne.chezmoi"
)

foreach ($Package in $Packages) {
    if ($DryRun) {
        Write-Host "[dry-run] winget install --id $Package --exact"
        continue
    }

    winget install `
        --id $Package `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        throw "winget failed while installing $Package"
    }
}
