$ENV:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
Invoke-Expression (&starship init powershell)

# set custom alias'
Set-Alias -Name tf -Value terraform