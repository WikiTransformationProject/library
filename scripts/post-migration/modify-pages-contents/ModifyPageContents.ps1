<#
    Sample script: How to modify the text content of a text web part.

    Note: This will replace the last page version (not add a new one).

    Important: There is a pretty way to work with text web parts, via Set-PnPPageTextPart, which unfortunately does not always work. Sometimes
      it removes the whole web part... That's why where is a second way to deal with page contents, which works on the raw page content that
      is stored in the CanvasContent1 field of the page's list item.

      Both ways are shown here. The pretty way is activated by setting $doesThePrettyWayWork to $true. The second way is activated by setting $doesTheUglyWayWork
      to $true. Don't set both at the same time.

    Prerequisites:
    - run with PowerShell 7
    - install the PnP.PowerShell module using this command: Install-Module PnP.PowerShell -Scope CurrentUser
    - log in with a Contributor account that is allowed to edit pages
#>

################################# CONFIGURATION START #################################
# the client (application) ID of the WikiTraccs Azure AD application (like in WikiTraccs.GUI)
# CHANGE ME!:
$wikiTraccsClientId = "31359c7f-bd7e-475c-86db-fdb8c937548e"
# the site of the page you want to modify
# CHANGE ME:
$siteUrl = "https://contoso.sharepoint.com/sites/site1"
# file name of the page to search the text web part in
# CHANGE ME:
$pageFilename = "SPACE-eProcurement-dashboard-123456789.aspx"
# the (HTML) text to be replaced; note: web part text content is HTML - so this contains tags like <p> etc.
# IMPORTANT: YOU WILL MOST LIKELY HAVE TO LOOK AT THE RAW PAGE CONTENT TO FIND THE TEXT TO REPLACE AS IT MIGHT CONTAIN ENCODED CHARACTERS
#   HAVE A LOOK AT THE $rawPageContent VARIABLE DOWN BELOW IN THE SCRIPT
# CHANGE ME:
$replaceWhat = '🚧'
# the (HTML) text to replace with; note: this replacement must not result in invalid HTML! make sure to HTML-encode entities like <, &, " etc.
# CHANGE ME:
$replaceWith = '🏗️'
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
if (-not $siteConnection -or $siteConnection.Url -ne $siteUrl) {
    $siteConnection = $null
}
if (-not $siteConnection) {
    Write-Host "Waiting for you to log in to the Microsoft login experience; note: this window might open behind the window you are currently in! Check for new windows in the task bar." -ForegroundColor Yellow
    $siteConnection = Connect-PnPOnline -Url $siteUrl -ClientId $wikiTraccsClientId -Interactive -ReturnConnection
}
# check connection
$site = Get-PnPSite -Connection $siteConnection
if (-not $site -or -not $site.Url -or $site.Url.ToString().TrimEnd("/") -ne $siteUrl.TrimEnd("/")) {
    Write-Error "[error] Could not connect to $siteUrl"
    exit
}
Write-Host "[ok] Connected to site '$siteUrl'" -ForegroundColor Green

$doesTheUglyWayWork = $true
if ($doesTheUglyWayWork) 
{
    $sitePagesLib = Get-PnPList "SitePages" -Connection $siteConnection
    $rootFolder = Get-PnPProperty -ClientObject $sitePagesLib -Property RootFolder -Connection $siteConnection
    # $rootFolder.ServerRelativeUrl is like "/sites/site1/SitePages"
    $fileUrl = "$($rootFolder.ServerRelativeUrl)/$pageFilename"
    Write-Host "Modifying raw content of page $($fileUrl)"
    $pageListItem = Get-PnPFile -Url $fileUrl -AsListItem -Connection $siteConnection

    # note: this content contains a mix of HTML and JSON, sometimes double or triple-encoded; simply replacing something in here will probably only work
    # for easy text replacements; otherwise more code is needed to cope with encodings
    $rawPageContent = $pageListItem["CanvasContent1"]

    # print raw content to console...
    $rawPageContent
    $newRawPageContent = $rawPageContent.Replace($replaceWhat, $replaceWith)
    $pageListItem["CanvasContent1"] = $newRawPageContent
    $pageListItem.Update()
    Invoke-PnPQuery -Connection $siteConnection
}

# unfortunately, this easy way to set text web part content via PnP PowerShell does not always work!?
$doesThePrettyWayWork = $false
if ($doesThePrettyWayWork) 
{
    $page = Get-PnPPage $pageFilename -Connection $siteConnection
    $pageTextWebParts = Get-PnPPageComponent -Page $page -Connection $siteConnection | Where-Object { $_.Type.Name -eq "PageText" }
    if (-not $pageTextWebParts -or -not $pageTextWebParts.Count)
    {
        Write-Host "No text web parts found, exiting"
        exit
    }

    Write-Host "[ok] Got $($pageTextWebParts.Count) text web parts, modifying first one (adjust code here if you want to select which web part to modify)" -ForegroundColor Green
    $textWebPart = $pageTextWebParts | Select-Object -First 1
    Write-Host "Handling text webpart with ID $($textWebPart.InstanceId)"
    $instanceId = $textWebPart.InstanceId
    # get the web part text content; this is HTML
    $webPartText = $textWebPart.Text

    # modify text content, here: replace an emoji
    $newWebPartText = $webPartText.Replace($replaceWhat, $replaceWith)

    Write-Host "Setting new web part content..."
    Set-PnPPageTextPart -Page $page -InstanceId $instanceId -Text $newWebPartText -Connection $siteConnection
    Write-Host "Done: Setting new web part content"
}