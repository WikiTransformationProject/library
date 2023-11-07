$commonScriptFilePath = Join-Path $PSScriptRoot ".." ".." "common" "CheckEnvironment.ps1"
. $commonScriptFilePath

<#
    Sample script: Get the storage format XML for a page from the "Confluence Content Snapshots (WikiTraccs)" library.

    Note: This is supported since WikiTraccs 1.9.

    Prerequisites:
    - run with PowerShell 7
    - install the PnP.PowerShell module using this command: Install-Module PnP.PowerShell -Scope CurrentUser
#>

################################# CONFIGURATION START #################################
# the client (application) ID of the WikiTraccs Azure AD application (like in WikiTraccs.GUI)
# CHANGE ME!:
$azureAdApplicationClientId = "31359c7f-bd7e-475c-86db-fdb8c937548e"
# WikiTraccs site URL that contains the "Confluence Content Snapshots (WikiTraccs)" library
# CHANGE ME:
$siteUrl = "https://contoso.sharepoint.com/sites/WikiTraccsStore"
# page ID to get the storage format XML for
# CHANGE ME:
$pageId = "8170101880"
#################################  CONFIGURATION END  #################################


# reuse an existing connection to a site to not have to log in every time the script runs
if (-not $connection -or $connection.Url -ne $siteUrl) {
    $connection = $null
}
if (-not $connection) {
    Write-Host "Waiting for you to log in to the Microsoft login experience; note: this window might open behind the window you are currently in! Check for new windows in the task bar." -ForegroundColor Yellow
    $connection = Connect-PnPOnline -Url $siteUrl -ClientId $azureAdApplicationClientId -Interactive -ReturnConnection
}
# check connection
$site = Get-PnPSite -Connection $connection
if (-not $site -or -not $site.Url -or $site.Url.ToString().TrimEnd("/") -ne $siteUrl.TrimEnd("/")) {
    Write-Error "[error] Could not connect to $siteUrl"
    exit
}
Write-Host "[ok] Connected to site '$siteUrl'" -ForegroundColor Green

<#
    Each file in the "Confluence Content Snapshots (WikiTraccs)" list (in the WikiTraccs site) contains the raw Confluence REST API result for a page and the page comments.

    The file is a JSON file, containing the Confluence API result as escaped JSON; which in turn contains the storage XML as escaped XML.

    The following code decodes this, until we have the raw storage format XML for the page.
#>
# find the list item by page ID
$listItem = Get-PnPListItem -List "Confluence Content Snapshots (WikiTraccs)" -Query "<View><Query><Where><Eq><FieldRef Name='WT_In_CfContentId'/><Value Type='Text'>$pageId</Value></Eq></Where></Query></View>" -Connection $connection
# get associated file for the list item
$fileItem = Get-PnPProperty $listItem File -Connection $connection
# read file content - it's JSON
$fileContentJson = Get-PnPFile $fileItem.ServerRelativeUrl -AsString -Connection $connection
$fileContentObject = ConvertFrom-Json $fileContentJson
# look at the "Page.Content" member, which contains the original Confluence REST API response
$pageRestApiResultJson = $fileContentObject.Data.'Page.Content' # note: use $fileContentObject.Data.'Page.Comments' to return the comments instead
$pageRestApiResultObject = ConvertFrom-Json $pageRestApiResultJson
# get the storage format XML from the original REST API response
$pageStorageFormatXml = $pageRestApiResultObject.body.storage.value
# this should print XML to the console
$pageStorageFormatXml