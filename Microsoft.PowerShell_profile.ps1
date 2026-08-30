#            ╭───────────────────────────────────────────────────────────╮
#            │                    PowerShell Profile                     │
#            │             Loaded at every start of session.             │
#            ╰───────────────────────────────────────────────────────────╯

# bash-like auto-complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

New-Alias -Name q -Value qalc
$env:JQ_COLORS = "95:91:35:33:92:36:36:94"

# ── Oh My Posh ──────────────────────────────────────────────────
function Set-EnvVar {
    $env:keki_cake   = [System.Environment]::GetEnvironmentVariable("keki_cake",   "User")
    $env:keki_layer  = [System.Environment]::GetEnvironmentVariable("keki_layer",  "User")
    $env:keki_layers = [System.Environment]::GetEnvironmentVariable("keki_layers", "User")
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force
# oh-my-posh init pwsh --config 'C:\Dev\OhMyPosh-theme.git\ayame.omp.json' | Invoke-Expression
(@(& oh-my-posh init pwsh --config='C:\Dev\OhMyPosh-theme.git\ayame.omp.json' --print) -join "`n") | Invoke-Expression

# ── Yam imports ───────────────────────────────────────────────
. $env:Yam\Syncthing.ps1
. $env:Yam\Yam.ps1
. $env:Yam\Nog.ps1
. $env:Yam\Git.ps1
. $env:Yam\Dashboard.ps1
. $env:Yam\KingSoopersReceiptHelper.ps1
. $env:Yam\Supply.ps1
. $env:Yam\FFmpeg.ps1

New-Alias -Name ksr -Value Add-KingSoopersReceiptToCSV

if (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
    Write-Host ' nog '       -NoNewline  -Back Blue    -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' yam '       -NoNewline  -Back Magenta -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' git '       -NoNewline  -Back Green   -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' syncthing ' -NoNewline  -Back Cyan    -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' dashboard ' -NoNewline  -Back White   -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' ffmpeg '    -NoNewline  -Back Green   -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' supply '    -Back Red   -Fore Black
}

New-Alias -Name supply -Value Add-SupplyItem

# ── Neovim and VSCode ───────────────────────────────────────────
New-Alias -Name vim   -Value nvim
New-Alias -Name v     -Value nvim
New-Alias -Name w     -Value wsl
New-Alias -Name vd    -Value vimdev
New-Alias -Name codev -Value codedev
New-Alias -Name c     -Value code
New-Alias -Name idea  -Value idea64
New-Alias -Name id    -Value idea
New-Alias -Name idev  -Value ideadev
Function v. {
    nvim .
}
Function c. {
    code .
}
Function id. {
    idea .
}
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
    param(
        [Alias('P')]
        [string]$Project,
        [Alias('C')]
        [switch]$Code,
        [Alias('V')]
        [switch]$Vim,
        [Alias('I')]
        [switch]$Idea
    )
    $Path = 'C:\Dev'
    if ($PSBoundParameters.ContainsKey('Project')) {
        $Path = "$Path\$Project"
    }
    Set-Location $Path
    if ($Code) {
        code .
    }
    if ($Vim) {
        vim .
    }
    if ($Idea) {
        idea .
    }
}
Function vimdev {
    param(
        [Alias('P')]
        [string]$Project
    )
    dev -Project $Project -Vim
}
Function codedev {
    param(
        [Alias('P')]
        [string]$Project
    )
    dev -Project $Project -Code
}
Function ideadev {
    param(
        [Alias('P')]
        [string]$Project
    )
    dev -Project $Project -Idea
}
$ProjectCompleter = {
    param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameter)

    $Path = 'C:\Dev'
    $Dirs = Get-ChildItem -Path $Path -Directory | Select-Object -ExpandProperty Name

    return $Dirs | Where-Object { $_ -like "$WordToComplete*" }
}
Register-ArgumentCompleter -CommandName dev     -ParameterName Project -ScriptBlock $ProjectCompleter
Register-ArgumentCompleter -CommandName vimdev  -ParameterName Project -ScriptBlock $ProjectCompleter
Register-ArgumentCompleter -CommandName codedev -ParameterName Project -ScriptBlock $ProjectCompleter
Register-ArgumentCompleter -CommandName ideadev -ParameterName Project -ScriptBlock $ProjectCompleter

Function cdls {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    Set-Location $Path
    Get-ChildItem
}

# ── fzf ─────────────────────────────────────────────────────────
Function fuzz {
    param(
            [Parameter(ValueFromPipeline)]
            [string]$Path,
            [Alias('F')]
            [switch]$File,
            [Alias('D')]
            [switch]$Directory
         )
    if (-Not $Path) {
        $Path = '.'
    }
    Get-ChildItem -Path $Path -Recurse -File:$File -Directory:$Directory | ForEach-Object { $_.FullName } | fzf
}
Function cdfuzz {
    param(
            [Parameter(ValueFromPipeline)]
            [string]$Path,
            [Alias('F')]
            [switch]$File,
            [Alias('D')]
            [switch]$Directory
         )
    if (-Not $Path) {
        $Path = '.'
    }
    $Choice = fuzz -Path $Path -File:$File -Directory:$Directory
    if ((Get-Item $Choice).PSIsContainer) {
        Set-Location $Choice
    }
    else {
        Split-Path $Choice -Parent | Set-Location
    }
}
Function openfuzz {
    param(
            [Parameter(ValueFromPipeline)]
            [string]$Path,
            [Alias('F')]
            [switch]$File,
            [Alias('D')]
            [switch]$Directory
         )
    if (-Not $Path) {
        $Path = '.'
    }
    Invoke-Item fuzz -Path $Path -File:$File -Directory:$Directory
}
function fzfreg {
    function to_escape($hex, $fg = $true) {
        $hex = $hex -replace '^#', ''
        $r = [System.Convert]::ToByte($hex.Substring(0, 2), 16)
        $g = [System.Convert]::ToByte($hex.Substring(2, 2), 16)
        $b = [System.Convert]::ToByte($hex.Substring(4, 2), 16)
        $z = $fg ? '3' : '4'
        return "`e[${z}8;2;${r};${g};${b}m"
    }

    $prev_enc  = $OutputEncoding
    $prev_cout = [Console]::OutputEncoding
    $prev_cin  = [Console]::InputEncoding

    try {
        $OutputEncoding           = [System.Text.UTF8Encoding]::new($false)
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

        $selected = Get-Content -Encoding utf8 -Raw $env:Ndz\Chishiki\manifest_register.csv `
            | ConvertFrom-Csv `
            | ForEach-Object { "$( $PSStyle.Foreground.Magenta )$( $_.Date )`t$( $PSStyle.Foreground.BrightMagenta )$( $_.'Manifest ID' )`t$( $PSStyle.Reset )$( $_.Note )" } `
            | fzf --ansi `
        
        if ($selected) {

            $date, $id, $note = $selected -split "`t"

            $ansi_rx = '\x1b\[[0-9;]*m'
            $date = $date -replace $ansi_rx, ''
            $id   = $id   -replace $ansi_rx, ''
            $note = $note -replace $ansi_rx, ''

            $r    = "`e[0m"

            $date = "$( to_escape '#322145' )${r}" `
                  + "$( to_escape '#322145' $false )$( to_escape '#B097CE' ) ${date} ${r}" `
                  + "$( to_escape '#322145' )$( to_escape '#130F1E' $false )${r}"
            $id   = "$( to_escape '#130F1E' )$( to_escape '#763B73' $false )${r}" `
                  + "$( to_escape '#763B73' $false )$( to_escape '#FF9BFF' ) ${id} ${r}" `
                  + "$( to_escape '#763B73')${r}"
            
            Write-Host "${date}${id} ${note}"
        }
    }
    finally {
        $OutputEncoding           = $prev_enc
        [Console]::OutputEncoding = $prev_cout
        [Console]::InputEncoding  = $prev_cin
    }
}


# ── komorebi ────────────────────────────────────────────────────
Function komo {
    komorebic start --whkd --bar
}

Function Open-Nog {
    vim "$env:Ndz\Nog\$env:COMPUTERNAME\$(Get-Date -Format 'yyyy-MM')\$(Get-Date -Format 'yyyy-MM-dd').log"
}

Function Open-Log {
    vim "$env:Ndz\Log\$env:COMPUTERNAME-$(Get-Date -Format 'yyyy-MM-dd').log"
}

Function Out-Image {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$Path
    )
    $Key = Get-Content "$env:NDZ\Ref\ImgBB\api-key" -Raw
    $Form = @{ image = Get-Item $Path }
    $Response = Invoke-WebRequest -Uri "https://api.imgbb.com/1/upload?key=$Key" -Method POST -Form $Form | ConvertFrom-Json
    if ($null -ne $Response.data.url) {
        $Response.data.url | Set-Clipboard
        Write-Host "URL `"$($Response.data.url)`" copied to clipboard."
    }
    else {
        Write-Error "Failed to upload image to ImgBB."
    }
}

Function Get-Dashboard {
    . "C:\Dev\Get-Dashboard.git\Get-Dashboard.ps1"
}

Function admin {
    Start-Process wt pwsh -Verb RunAs
}

function Set-FileSystemDates {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$DateTimeString,

        [switch]$All,
        [switch]$Created,
        [switch]$Modified,
        [switch]$Accessed
    )

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    if (-not ($All -or $Created -or $Modified -or $Accessed)) {
        throw "Specify at least one of: -All, -Created, -Modified, -Accessed"
    }

    $dt   = [datetime]::Parse($DateTimeString)
    $item = Get-Item $FilePath

    if ($All -or $Created)  { $item.CreationTime   = $dt }
    if ($All -or $Modified) { $item.LastWriteTime  = $dt }
    if ($All -or $Accessed) { $item.LastAccessTime = $dt }

    $applied = if ($All) {
        "All (Created, Modified, Accessed)"
    } else {
        ($Created, $Modified, $Accessed).ForEach({ $_ }) |
            Where-Object { $_ } |
            ForEach-Object { $_.ToString() } |
            # label each active switch
            & {
                $labels = @()
                if ($Created)  { $labels += "Created" }
                if ($Modified) { $labels += "Modified" }
                if ($Accessed) { $labels += "Accessed" }
                $labels -join ", "
            }
    }

    Write-Host "Updated [$applied] timestamp(s) on '$FilePath' to $dt"
}

Import-Module Terminal-Icons
