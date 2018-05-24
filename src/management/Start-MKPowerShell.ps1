$script:ConfigFileParentPath 
function Start-MKPowerShell {
    [CmdletBinding(PositionalBinding = $False)]
    Param(
        [Parameter(Mandatory = $False)]
        [String]$ConfigFilePath = $script:MKPowerShellConfigFilePath
    )
    
    if ((Test-Path -Path $ConfigFilePath) -eq $false) {
        $script:ConfigFileParentPath = $(Split-Path $ConfigFilePath -Parent)
        if ((Test-Path -Path $script:ConfigFileParentPath) -eq $false) {
            New-Item -Path $script:ConfigFileParentPath -ItemType Directory -Verbose
        }

        Copy-Item -Path "$PSScriptRoot\..\..\resources\MK.PowerShell-config.json" -Destination $script:ConfigFileParentPath -Verbose -PassThru
    }

    Restore-RememberLastLocation -Initialize
    Restore-QuickRestartSetting -Initialize
    Backup-Sources -Initialize
    Restore-History -Initialize
    Restore-Formats -Initialize

    Register-Shutdown
}

# NoExport: Restore-RememberLastLocation
function Restore-RememberLastLocation {
    [CmdletBinding()]
    Param(
        [switch]$Initialize
    )

    if ((Get-MKPowerShellSetting -Name 'TurnOnRememberLastLocation') -eq $true) {
        Set-Alias sl Set-LocationAndStore -Scope Global -Force
        Write-Host "'sl' alias is now mapped to 'Set-LocationAndStore'." -ForegroundColor Green

        if ($Initialize.IsPresent) {
            $LastLocation = Get-MKPowerShellSetting -Name 'LastLocation'
            if ($LastLocation -ne '') {
                Set-LocationAndStore -Path $LastLocation
            }
            else {
                Set-LocationAndStore -Path $(Get-Location)
            }
        }
    }
    else {
        Set-Alias sl Set-Location -Scope Global -Force
        Write-Host "'sl' alias is now mapped to 'Set-Location'." -ForegroundColor Green
    }
}

# NoExport: Restore-QuickRestartSetting
function Restore-QuickRestartSetting {
    [CmdletBinding()]
    Param(
        [switch]$Initialize
    )

    if ((Get-MKPowerShellSetting -Name 'TurnOnQuickRestart') -eq $true) {
        Set-Alias pwsh Restart-PWSH -Scope Global
        Write-Host "'pwsh' alias is now mapped to 'Restart-PWSH'." -ForegroundColor Green

        Set-Alias pwsha Restart-PWSHAdmin -Scope Global
        Write-Host "'pwsha' alias is now mapped to 'Restart-PWSHAdmin'." -ForegroundColor Green
    }
    else {
        if (-not $Initialize.IsPresent) { 
            Remove-Alias pwsh -Scope Global
            Write-Host "'pwsh' alias has been removed." -ForegroundColor Green

            Remove-Alias pwsha -Scope Global
            Write-Host "'pwsha' alias has been removed." -ForegroundColor Green
        }
    }
}

function Restore-History {
    [CmdletBinding()]
    Param(
        [switch]$Initialize
    )

    $IsHistoryRecordingEnabled = (Get-MKPowerShellSetting -Name 'TurnOnHistoryRecording') -eq $true

    if ($IsHistoryRecordingEnabled) { 

        $HistoryLocation = Get-MKPowerShellSetting -Name 'HistoryLocation'
        if (($HistoryLocation -eq '') -or (Test-Path -Path $HistoryLocation -ErrorAction SilentlyContinue) -eq $false) {
            $SessionHistoriesPath = New-Item -Path $script:ConfigFileParentPath"\SessionHistories.csv" -ItemType File | Select-Object -ExpandProperty FullName

            Set-MKPowerShellSetting -Name 'HistoryLocation' -Value $SessionHistoriesPath
            
            Write-Host "History file has been created." -ForegroundColor Green
        }
        else {
            Import-History

            Write-Host "History is restored from previous session(s)." -ForegroundColor Green
        }
    }
}

function Restore-Formats {
    [CmdletBinding()]
    Param(
        [switch]$Initialize
    )
    
    # TODO: can't seem to have manifest's 'FormatsToProcess' key  to load files listed in it.  So 
    # manually doing it for now.
    if ((Get-MKPowerShellSetting -Name 'TurnOnBetterFormats') -eq $true) {
        # setting this to -1 to display/view all items for ListItems.  For instance, Get-Module's 
        # ExportedFunction
        $global:FormatEnumerationLimit = -1
        
        $ModuleHome = $MyInvocation.ScriptName | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
        $FormatFilePaths = Get-ManifestKey -Path $ModuleHome -Key 'FormatsToProcess' | `
            ForEach-Object {Join-Path -Path $ModuleHome -ChildPath $_}
        
        Update-FormatData -PrependPath $FormatFilePaths
    }
}