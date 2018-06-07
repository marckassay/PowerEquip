using module .\..\Get-ModuleInfo.ps1

# RegEx pattern is from here: https://regex101.com/r/gG8cK7/1
function Update-SemVer {
    [CmdletBinding(PositionalBinding = $true)]
    Param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = "ByPath")]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidatePattern("^(?'MAJOR'0|(?:[1-9]\d*))\.(?'MINOR'0|(?:[1-9]\d*))\.(?'PATCH'0|(?:[1-9]\d*))(?:-(?'prerelease'(?:0|(?:[1-9A-Za-z-][0-9A-Za-z-]*))(?:\.(?:0|(?:[1-9A-Za-z-][0-9A-Za-z-]*)))*))?(?:\+(?'build'(?:0|(?:[1-9A-Za-z-][0-9A-Za-z-]*))(?:\.(?:0|(?:[1-9A-Za-z-][0-9A-Za-z-]*)))*))?$")]
        [String]$Value,

        [switch]$BumpMajor,

        [switch]$BumpMinor,

        [switch]$BumpPatch
    )

    $ModuleInfo = Get-ModuleInfo -Path $Path
    $Path = ($ModuleInfo | Select-Object -ExpandProperty Values).Path

    if (-not $Value) {
        $Version = ($ModuleInfo | Select-Object -ExpandProperty Values).Version
        $Major = $Version.Major
        $Minor = $Version.Minor
        $Patch = $Version.Build

        if ($BumpMajor.IsPresent) {
            $Major += 1
        }
        
        if ($BumpMinor.IsPresent) {
            $Minor += 1
        }
        
        if ($BumpPatch.IsPresent) {
            $Patch += 1
        }

        $Value = "$Major.$Minor.$Patch"
    }

    Update-ModuleManifest -Path $Path -ModuleVersion $Value | Out-Null
    Update-RootModuleUsingStatements -Path $Path -SourceDirectory '.\src\' | Update-ManifestFunctionsToExportField

    $Value
}