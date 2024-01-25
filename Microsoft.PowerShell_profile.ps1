#            ╭───────────────────────────────────────────────────────────╮
#            │                    PowerShell Profile                     │
#            │             Loaded at every start of session.             │
#            ╰───────────────────────────────────────────────────────────╯

# bash-like auto-complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# ── Oh My Posh ──────────────────────────────────────────────────
function Set-EnvVar {
    $env:keki_cake = [System.Environment]::GetEnvironmentVariable("keki_cake", "User")
    $env:keki_layer = [System.Environment]::GetEnvironmentVariable("keki_layer", "User")
    $env:keki_layers = [System.Environment]::GetEnvironmentVariable("keki_layers", "User")
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force
oh-my-posh init pwsh --config 'C:\Dev\OhMyPosh-theme.git\ayame.omp.json' | Invoke-Expression

# ── Neovim and VSCode ───────────────────────────────────────────
New-Alias -Name vim -Value nvim
New-Alias -Name v -Value nvim
New-Alias -Name w -Value wsl
New-Alias -Name vd -Value vimdev
New-Alias -Name codev -Value codedev
New-Alias -Name c -Value code
Function v. {
    nvim .
}
Function c. {
    code .
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
Register-ArgumentCompleter -CommandName codedev -ParameterName P -ScriptBlock $ProjectCompleter
Register-ArgumentCompleter -CommandName dev -ParameterName P -ScriptBlock $ProjectCompleter

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
    komorebic start -a
}
$Env:KOMOREBI_CONFIG_HOME = $env:ndz + '\com\komorebi'
$Env:WHKD_CONFIG_HOME = $env:ndz + '\com\whkd'

# ── Git ─────────────────────────────────────────────────────────
Function Set-GitHooks {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("P")]
        [string]$Path
    )

    if (-Not (Test-Path -Path $Path\.git)) {
        Write-Error "Not a git repository: $Path"
        Return
    }
    if (-Not (Test-Path -Path $Path\.git\hooks)) {
        mkdir $Path\.git\hooks
    }

    Copy-Item $env:Ndz\Script\commit-msg-master.py $Path\.git\hooks
    Rename-Item $Path\.git\hooks\commit-msg-master.py commit-msg
    Write-Host "Added commit-msg to $Path\.git\hooks"

    Read-Host 'Project name' | Set-Content -Path $Path\.git\description
}
$Completer = {
    param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameter)

    $Path = Get-Location
    $Dirs = Get-ChildItem -Path $Path -Directory | Select-Object -ExpandProperty Name

    return $Dirs | Where-Object { $_ -like "$WordToComplete*" }
}
Register-ArgumentCompleter -CommandName Add-GitHooks -ParameterName P -ScriptBlock $Completer

Function Set-License {
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [string[]]$Path,
        [Parameter(Mandatory, Position=1)]
        [string]$License
    )

    $LicensePath = Join-Path -Path $env:Ndz\Com\License -ChildPath $License

    for ($i = 0; $i -lt $Path.Count; $i++) {
        Copy-Item -Path $LicensePath -Destination $Path[$i]
        Rename-Item -Path (Join-Path -Path $Path[$i] -ChildPath $License) -NewName 'LICENSE'
    }
}
Register-ArgumentCompleter -CommandName Set-License -ParameterName License -ScriptBlock {
    param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameter)

    $Licenses = Get-ChildItem -Path $env:Ndz\Com\License -File | Select-Object -ExpandProperty Name

    return $Licenses | Where-Object { $_ -like "$WordToComplete*" }
}

Function Get-DevGitStatus {
    $DevLocation = 'C:\Dev'
    $PrevCWD = (Get-Item .).FullName
    Set-Location $DevLocation
    $RepositoryCount = (Get-ChildItem -Directory).Count
    $CountedRepositories = 0
    $StatusTable = @(@{}) * $RepositoryCount
    Get-ChildItem -Directory |
            Where-Object { $_.BaseName.EndsWith('.git') } |
            ForEach-Object {
                $PercentComplete = [math]::Round($CountedRepositories / $RepositoryCount * 100)
                Write-Progress -Activity 'Git Status Progress' -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
                Set-Location $_.FullName
                $StatusOutput = (git status --porcelain)
                if ($StatusOutput.Count -gt 0) {
                    $NewFiles = 0
                    $DeletedFiles = 0
                    $RenamedFiles = 0
                    $ModifiedFiles = 0
                    $UntrackedFiles = 0
                    
                    for ($i = 0; $i -lt $StatusOutput.Count; $i++) {
                        $ThisLine = $StatusOutput[$i]
                        if (([string]$ThisLine).Length -gt 1) {
                            $Chars = $ThisLine.ToCharArray(0, 2)
                            if ($Chars[0] -eq [char]'A') { $NewFiles++ }
                            if ($Chars[0] -eq [char]'D') { $DeletedFiles++ }
                            if ($Chars[0] -eq [char]'R') { $RenamedFiles++ }
                            if ($Chars[1] -eq [char]'M') { $ModifiedFiles++ }
                            if ($Chars[0] -eq [char]'?') { $UntrackedFiles++ }
                        }
                    }
                    
                    $StatusTable[$CountedRepositories] = [PSCustomObject]@{
                        Repository = $_.BaseName;
                        New = $NewFiles;
                        Deleted = $DeletedFiles;
                        Renamed = $RenamedFiles;
                        Modified = $ModifiedFiles;
                        Untracked = $UntrackedFiles;
                    }
                    $CountedRepositories++
                }
            }

    Set-Location $PrevCWD
    if ($CountedRepositories -gt 0) {
        $StatusTable[0..($CountedRepositories -1)]
    }
    else {
        Write-Host "All repositories are up to date."
        0
    }
}

Import-Module posh-git
