# symbolic links
Function New-Link($Target, $Link) {
    New-Item -Path $Link -ItemType SymbolicLink -Value $Target
}

# bash-like auto-complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# [vim] -->
New-Alias -Name vim -Value nvim
New-Alias -Name vd -Value vimdev
New-Alias -Name codev -Value codedev
# edit the neovim config
Function vimcon {
    $CurrentDir = Get-Location
    Set-Location $env:localappdata\nvim
    vim .
    Set-Location $CurrentDir
}
Function vimprofile {
    $CurrentDir = Get-Location
    Split-Path -Parent $Profile | Set-Location
    vim $Profile
    Set-Location $CurrentDir
}
Function codeprofile {
    $CurrentDir = Get-Location
    Split-Path -Parent $Profile | Set-Location
    code $Profile
    Set-Location $CurrentDir
}
Function dev {
    param([string]$P, [switch]$C, [switch]$V)
    $Path = 'C:\Dev'
    if ($PSBoundParameters.ContainsKey('P')) {
        $Path = "$Path\$P"
    }
    Set-Location $Path
    if ($C) {
        code .
    }
    if ($V) {
        vim .
    }
}
Function vimdev {
    param([string]$P)
    dev -P $P -V
}
Function codedev {
    param([string]$P)
    dev -P $P -C
}
$ProjectCompleter = {
    param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameter)

    $Path = 'C:\Dev'
    $Dirs = Get-ChildItem -Path $Path -Directory | Select-Object -ExpandProperty Name

    return $Dirs | Where-Object { $_ -like "$WordToComplete*" }
}

Register-ArgumentCompleter -CommandName vimdev -ParameterName P -ScriptBlock $ProjectCompleter
Register-ArgumentCompleter -CommandName dev -ParameterName P -ScriptBlock $ProjectCompleter

Function cdls {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    Set-Location $Path
    Get-ChildItem
}

# [komorebi] -->
Function komo {
    komorebic start -a
}
$Env:KOMOREBI_CONFIG_HOME = $env:ndz + '\com\komorebi'
$Env:WHKD_CONFIG_HOME = $env:ndz + '\com\whkd'
