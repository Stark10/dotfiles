$env:XDG_CONFIG_HOME = Join-Path $HOME ".config"
$env:MISE_GLOBAL_CONFIG_FILE = Join-Path $env:XDG_CONFIG_HOME "mise/config.toml"

if (Get-Command mise -ErrorAction SilentlyContinue) {
    (& mise activate pwsh | Out-String) | Invoke-Expression
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (& zoxide init powershell | Out-String) | Invoke-Expression
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config (Join-Path $env:XDG_CONFIG_HOME "oh-my-posh/dev.omp.json") | Invoke-Expression
}

function vim { nvim @args }
function ll { eza --icons=auto --group-directories-first --long --git @args }
function la { eza --icons=auto --group-directories-first --all @args }
