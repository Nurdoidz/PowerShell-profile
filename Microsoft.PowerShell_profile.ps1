# bash-like auto-complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# [vim] -->
New-Alias -Name vim -Value nvim
# edit the neovim config
function vimcon {
    $currentDir = Get-Location
    cd $env:localappdata\nvim
    vim .
    cd $currentDir
}

# [komorebi] -->
function komo {
    komorebic start -a
}

