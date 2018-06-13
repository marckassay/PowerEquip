using module .\..\dynamicparams\GetModuleNameSet.ps1

function Get-MKModuleInfo {
    [CmdletBinding()]
    [OutputType([PSObject])]
    Param
    (
        [Parameter(Mandatory = $False)]
        [string]
        $Path = (Get-Location | Select-Object -ExpandProperty Path)
    )

    DynamicParam {
        return GetModuleNameSet
    }
    
    begin {
        $Name = $PSBoundParameters['Name']
    }

    end {
        if (-not $Name) {
            # if backslash is at the end and this value is used with Import-Module, it will fail to import
            $Item = Get-Item ($Path.Trim().TrimEnd('\'))

            if ($(Test-Path $Item.FullName -PathType Leaf)) {
                if ($Item.Extension -eq '.psd1') {
                    $ModuleInfo = Test-ModuleManifest $Item
                }
                elseif ($Item.Extension -eq '.psm1') {
                    $PredicatedManifestPath = Join-Path -Path $Item.Parent -ChildPath ($Item.BaseName + ".psd1")
                    if (Test-Path $PredicatedManifestPath) {
                        $ModuleInfo = Test-ModuleManifest $PredicatedManifestPath
                    }
                    else {
                        $RootModule = $Item
                        $ModuleBase = $Item.Directory.FullName
                        $Name = $Item.BaseName
                    }
                }
            }
            else {
                $PredicatedManifestItem = Get-ChildItem -Path ($Item.FullName) -Include '*.psd1' -Recurse -Depth 0 | `
                    Select-Object -First 1 | `
                    Select-Object -ExpandProperty FullName  
        
                if ($PredicatedManifestItem) {
                    $ModuleInfo = Test-ModuleManifest $PredicatedManifestItem
                }
                else {
                    $PredicatedModuleItem = Get-ChildItem -Path ($Item.FullName) -Include '*.psm1' -Recurse -Depth 0 | `
                        Select-Object -First 1

                    $RootModule = $PredicatedModuleItem
                    $ModuleBase = $PredicatedModuleItem.FullName
                    $Name = $PredicatedModuleItem.BaseName
                }
            }
        }
        elseif ($Name) {
            $ModuleInfo = Get-Module -Name $Name
        }

        if ($ModuleInfo) {
            $RootModule = $ModuleInfo.RootModule
            $ModuleBase = $ModuleInfo.ModuleBase
            $Name = $ModuleInfo.Name
        }

        $ManifestPath = "$ModuleBase\$Name.psd1"
        return [psobject]$ModuleInfo = @{
            Info         = $ModuleInfo
            ManifestPath = $ManifestPath
            RootModule   = $RootModule
            ModuleBase   = $ModuleBase
            Name         = $Name
        }
    }
}