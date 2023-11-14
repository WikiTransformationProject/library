$commonScriptFilePath = Join-Path $PSScriptRoot ".." ".." "common" "CheckEnvironment.ps1"
. $commonScriptFilePath

<#
    Sample script: Create a mapping between the SharePoint pages of a site and the original Confluence page.
      This can be useful when it's necessary to redirect external sources to the new targets.

      This script uses the metadata stored with each migrated page to generate possible links to the source Confluence pages. This is 
      possible because Confluence page links follow certain schemes that make use of page metadata.

    Prerequisites:
    - run with PowerShell 7
    - install the PnP.PowerShell module using this command: Install-Module PnP.PowerShell -Scope CurrentUser
#>

################################# CONFIGURATION START #################################
# the client (application) ID of the WikiTraccs Azure AD application (like in WikiTraccs.GUI)
# CHANGE ME!:
$azureAdApplicationClientId = "31359c7f-bd7e-475c-86db-fdb8c937548e"
# Link mapping CSV will be created for pages in this site
# CHANGE ME:
$siteUrl = "https://contoso.sharepoint.com/sites/site1"
#################################  CONFIGURATION END  #################################

$connection = ConnectOrReuse $connection $siteUrl $azureAdApplicationClientId

$csvRows = @()
$items = Get-PnPListItem -List "SitePages" -Fields ID,Title,WT_In_CfSpaceKey,WT_In_CfContentId,WT_In_CfTitle,WT_In_CfSpaceName,WT_In_CfTinyLink,WT_In_CfSiteId -PageSize 4999 -Connection $connection
foreach ($item in $items) {
    if (-not $item["WT_In_CfSiteId"]) 
    {
        continue
    }

    # like http://localhost:8090/display/S2/S2 Home
    $pageTitleLink = "$($item["WT_In_CfSiteId"])/display/$($item["WT_In_CfSpaceKey"])/$($item["WT_In_CfTitle"])"
    $pageTitleLink

    # like http://localhost:8090/display/S2/S2+Home
    $pageTitleLink2 = "$($item["WT_In_CfSiteId"])/display/$($item["WT_In_CfSpaceKey"])/$($item["WT_In_CfTitle"]?.Replace(" ", "+"))"
    $pageTitleLink2
    
    # like http://localhost:8090/pages/viewpage.action?spaceKey=S2&title=S2 Home
    $pageTitleLink3 = "$($item["WT_In_CfSiteId"])/pages/viewpage.action?spaceKey=$($item["WT_In_CfSpaceKey"])&title=$($item["WT_In_CfTitle"])"
    $pageTitleLink3

    # like http://localhost:8090/pages/viewpage.action?spaceKey=S2&title=S2+Home
    $pageTitleLink4 = "$($item["WT_In_CfSiteId"])/pages/viewpage.action?spaceKey=$($item["WT_In_CfSpaceKey"])&title=$($item["WT_In_CfTitle"]?.Replace(" ", "+"))"
    $pageTitleLink4

    # like http://localhost:8090/pages/viewpage.action?pageId=1572870
    $pageIdLink = "$($item["WT_In_CfSiteId"])/pages/viewpage.action?pageId=$($item["WT_In_CfContentId"])"
    $pageIdLink

    # like http://localhost:8090/x/BgAY
    $pageTinyLink = "$($item["WT_In_CfSiteId"])$($item["WT_In_CfTinyLink"])"
    $pageTinyLink

    $fileItem = Get-PnPProperty $item File -Connection $connection
    $spPageLink = $fileItem.ServerRelativeUrl
    $spPageLink

    $csvContent = [PSCustomObject]@{
        SharePointPageLink = $spPageLink
        PageTitleLink = $pageTitleLink2
        PageTitleLinkAlt = $pageTitleLink3
        PageIdLink = $pageIdLink
        PageTinyLink = $pageTinyLink
    }


    $csvRows += $csvContent
}

$csvRows | Export-Csv -Path "./linkmapping.csv" -Append