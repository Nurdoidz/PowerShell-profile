# bash-like auto-complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# [vim] -->
New-Alias -Name vim -Value nvim
# edit the neovim config
function vimcon {
    $currentDir = Get-Location
    Set-Location $env:localappdata\nvim
    vim .
    Set-Location $currentDir
}

# [komorebi] -->
function komo {
    komorebic start -a
}

