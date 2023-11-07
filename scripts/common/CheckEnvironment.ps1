# stop as soon as there is an error, to be safe
$ErrorActionPreference = 'Stop'

<#
  Check that PowerShell version is up to date.
#>
$expectedPsMajorVersion = 7
$expectedPsMinorVersionMin = 2
if ($PSVersionTable.PSVersion.Major -ne $expectedPsMajorVersion -or $PSVersionTable.PSVersion.Minor -lt $expectedPsMinorVersionMin) 
{
    Write-Error "[error] Expected PowerShell version >= $($expectedPsMajorVersion).$($expectedPsMinorVersionMin) but found $($PSVersionTable.PSVersion); you might need to install a version, or (e.g. in Visual Studio Code) explicitly select another version"
    exit
}
Write-Host "[ok] Using PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Green

<#
  Check that the PnP.PowerShell module is available and has the right version.
#>
$version = $null
if (-not (Get-Module "PnP.PowerShell"))
{
    $null = Import-Module "PnP.PowerShell" -ErrorAction SilentlyContinue
}
if (-not (Get-Module "PnP.PowerShell"))
{
    Write-Error "[error] PowerShell module PnP.PowerShell is not installed; use 'Install-Module PnP.PowerShell -Scope CurrentUser' to install the module, before running this script"
    exit
}
Write-Host "[ok] Imported module PnP.PowerShell" -ForegroundColor Green

$version = Get-Module "PnP.PowerShell" | Select-Object -ExpandProperty Version
$expectedMajorVersion = 2
$expectedMinorVersionMin = 2
if ($version.Major -ne $expectedMajorVersion -or $version.Minor -lt $expectedMinorVersionMin)
{
    Write-Error "[error] Expected PnP.PowerShell version >= $($expectedMajorVersion).$($expectedMinorVersionMin) but found $($version.ToString())"
    exit
}
Write-Host "[ok] Using PnP.PowerShell $($version)" -ForegroundColor Green