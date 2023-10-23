<#
    Use this script to toggle comments for migrated pages on or off, on a given site.

    Prerequisites:
    - run with PowerShell 7
    - install the PnP.PowerShell module using this command: Install-Module PnP.PowerShell -Scope CurrentUser
    - log in with a site collection administrator or site owner of the site you are going to toggle the comments for
#>

################################# CONFIGURATION START #################################
# the client (application) ID of the WikiTraccs Azure AD application (like in WikiTraccs.GUI)
# CHANGE ME!:
$wikiTraccsClientId = "31359c7f-bd7e-475c-86db-fdb8c937548e"
# the site you want to enable or disable the page comments for; use a site collection or site owner account to connect
# CHANGE ME:
$siteToEnableCommentsFor = "https://contoso.sharepoint.com/sites/test1"
# enable or disable the comments
# CHANGE ME (either $true, or $false):
$enableComments = $true
#################################  CONFIGURATION END  #################################

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

# reuse an existing connection to a site to not have to log in every time the script runs
if (-not $siteConnection -or $siteConnection.Url -ne $siteToEnableCommentsFor) {
    $siteConnection = $null
}
if (-not $siteConnection) {
    Write-Host "Waiting for you to log in to the Microsoft login experience; note: this window might open behind the window you are currently in! Check for new windows in the task bar." -ForegroundColor Yellow
    $siteConnection = Connect-PnPOnline -Url $siteToEnableCommentsFor -ClientId $wikiTraccsClientId -Interactive -ReturnConnection
}
# check connection
$site = Get-PnPSite -Connection $siteConnection
if (-not $site -or -not $site.Url -or $site.Url.ToString().TrimEnd("/") -ne $siteToEnableCommentsFor.TrimEnd("/")) {
    Write-Error "[error] Could not connect to $siteToEnableCommentsFor"
    exit
}
Write-Host "[ok] Connected to site '$siteToEnableCommentsFor'" -ForegroundColor Green

Write-Host "Now getting all a list of all pages - this might take a while depending on the number of pages in the site..."
# get a list of all pages
$pageItems = Get-PnPListItem -List "SitePages" -PageSize 1999 -Connection $siteConnection
if (-not $pageItems -or -not $pageItems.Count) {
    Write-Error "[error] Could not get page items from Site Pages library"
    exit
}
Write-Host "Found $($pageItems.Count) pages; now going through all of them to set commenting to $enableComments"

$wikiTraccsPageContentTypeIdBase = "0x0101009D1CB255DA76424F860D91F20E6C411800C7482925E428D14785466663A30C9B33"
# go through all pages and toggle comments; skip non-migrated sites
foreach ($pageItem in $pageItems)
{
    $pageName = $pageItem["FileLeafRef"]
    if ($pageItem["ContentTypeId"] -notlike "$($wikiTraccsPageContentTypeIdBase)*") {
        Write-Host "Skipping non-migrated page '$pageName'" -ForegroundColor Gray
        continue
    }
    if ($enableComments) {
        Write-Host "Enabling comments for migrated page '$pageName'" -ForegroundColor White
        $null = Set-PnPClientSidePage -Identity $pageName -CommentsEnabled:$true -Connection $siteConnection
    } else {
        Write-Host "Disabling comments for migrated page '$pageName'" -ForegroundColor White
        $null = Set-PnPClientSidePage -Identity $pageName -CommentsEnabled:$false -Connection $siteConnection
    }
}
Write-Host "Done"