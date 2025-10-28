#            ╭───────────────────────────────────────────────────────────╮
#            │                    PowerShell Profile                     │
#            │             Loaded at every start of session.             │
#            ╰───────────────────────────────────────────────────────────╯

# bash-like auto-complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

New-Alias -Name q -Value qalc

# ── Oh My Posh ──────────────────────────────────────────────────
function Set-EnvVar {
    $env:keki_cake   = [System.Environment]::GetEnvironmentVariable("keki_cake", "User")
    $env:keki_layer  = [System.Environment]::GetEnvironmentVariable("keki_layer", "User")
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

if ($PSCmdlet.MyInvocation.InvocationName -eq 'Interactive') {
    Write-Host ' nog '       -NoNewline  -Back Blue    -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' yam '       -NoNewline  -Back Magenta -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' git '       -NoNewline  -Back Green   -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' syncthing ' -NoNewline  -Back Cyan    -Fore Black
    Write-Host ' '           -NoNewline
    Write-Host ' dashboard ' -Back White -Fore Black
}

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
Register-ArgumentCompleter -CommandName dev -ParameterName Project -ScriptBlock $ProjectCompleter
Register-ArgumentCompleter -CommandName vimdev -ParameterName Project -ScriptBlock $ProjectCompleter
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

Function Split-Markdown {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("M")]
        [string]$Markdown,
        [PSDefaultValue(Help=1990)]
        [Alias("L")]
        [int]$Length = 1990
    )

    $Paragraphs = $Markdown -Split '\r?\n'
    $Chunks = [System.Collections.ArrayList]::new()
    $Chunk = ''
    for ($i = 0; $i -lt $Paragraphs.Count; $i++) {
        if ($Chunk.Length + $Paragraphs[$i].Length + 12 -le $Length) {
            if ($Paragraphs[$i].Trim().Length -gt 0) {
                $Chunk += $Paragraphs[$i] + "`n`n"
            }
        }
        else {
            $Chunks.Add($Chunk)
            $Chunk = ''
        }
    }
    if ($Chunk.Length -gt 0) {
        $Chunks.Add($Chunk)
    }
    for ($i = 0; $i -lt $Chunks.Count; $i++) {
        $PartString = "$($i + 1)/$($Chunks.Count)"
        $Chunk = $Chunks[$i]
        Set-Clipboard "$Chunk($PartString)"
        Write-Host "(Part $PartString, $($Chunk.Length + $PartString.Length + 2) characters) copied to clipboard. Press enter to continue..."
        Read-Host
    }
}

# ── komorebi ────────────────────────────────────────────────────
Function komo {
    komorebic start --whkd
}

Function Add-Sermons {
    $CurrentDir = Get-Location
    Set-Location 'F:\Plex\Videos\Sermon'
    $Links = (Get-Clipboard -Raw) -split "`n"
    $Known = (Get-Content known.txt -Raw) -split "`n"
    $Links | Where-Object {
        -not $Known.Contains($_.Substring(32, 11))
    } | ForEach-Object {
        yt-dlp $_ --output "Grace City Denver - Sunday Service - %(upload_date>%Y-%m-%d)s - %(title)s [%(id)s]"
        Add-Content .\known.txt $_.Substring(32, 11)
    }
    Set-Location $CurrentDir
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
