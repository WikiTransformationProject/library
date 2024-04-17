$ErrorActionPreference = 'Stop'
$commonScriptFilePath = Join-Path $PSScriptRoot ".." ".." "common" "CheckEnvironment.ps1"
if (-not (Test-Path $commonScriptFilePath)) {
    Write-Error "Cannot find common script file $commonScriptFilePath"
}
. $commonScriptFilePath

<#
    This script creates test pages and page hierarchy TESTING the page tree.

    This creates TEST data. It also shows how to manually fill generate hierarchy data for WikiPakk.

    Two input files are used:
    - hierarchy-table.csv - contains the hierarchy that would normally be created by moving tree nodes around manually, or when creating new SharePoint pages
    - sitepages-lib.csv - contains data about to-be created pages

    The existing files already contain test rows to create about 2000 pages:
    - root level
    - child level
    - grand child level
    - mix of migrated and vanilla pages
    - "manually" relocated pages via hierarchy list
#>

################################# CONFIGURATION START #################################
# the client (application) ID of the Azure AD application
# CHANGE ME!:
$azureAdApplicationClientId = "31359c7f-bd7e-475c-86db-fdb8c937548e"
# WikiTraccs site URL where test pages will be created AND potentially deleted; use a new site for that
# CHANGE ME:
$siteUrl = "https://wikitransformationproject.sharepoint.com/sites/2024-04-16-test"
# path to WikiTraccs; this script uses a PnP template that is also used by WikiTraccs and that can be found in a sub directory
# CHANGE ME:
$wikiTraccsRootPath = "/home/user/00_Repos/wikitraccs-code/WikiTraccs.Console/bin/Debug/net6.0"
#################################  CONFIGURATION END  #################################




$connection = ConnectOrReuse $connection $siteUrl $azureAdApplicationClientId

# Define the path to the CSV file
$pagesLibCsvFilePath = Join-Path $PSScriptRoot "sitepages-lib.csv"
if (-not (Test-Path $pagesLibCsvFilePath)) {
    Write-Error "Cannot find Site Pages CSV file $pagesLibCsvFilePath"
}
$hierarchyListCsFilePath = Join-Path $PSScriptRoot "hierarchy-list.csv"
if (-not (Test-Path $hierarchyListCsFilePath)) {
    Write-Error "Cannot find hierarchy list CSV file $hierarchyListCsFilePath"
}

$wikiTraccsSitePageContentTypeName = "Site Page (transformed by WikiTraccs)"
$wikiTraccsSitePageContentType = Get-PnPContentType -Identity $wikiTraccsSitePageContentTypeName -Connection $connection -ErrorAction SilentlyContinue
$sitePagesLib = Get-PnPList "SitePages" -Connection $connection
$wikiTraccsSitePageContentTypeOnList = Get-PnPContentType -List $sitePagesLib -Identity $wikiTraccsSitePageContentTypeName -Connection $connection -ErrorAction SilentlyContinue
if (-not $wikiTraccsSitePageContentType -or -not $wikiTraccsSitePageContentTypeOnList) 
{
    $templatePath = Join-Path $wikiTraccsRootPath "Stores" "SPO" "TargetSite_PagesLibraryFieldsAndContentType.xml"
    if (-not (Test-Path $templatePath))
    {
        Write-Error "Cannot find template to provision WikiTraccs fields and content type"
    }
    # note: this is also what WikiTraccs does when preparing the site for the first time
    Invoke-PnPSiteTemplate -Connection $connection -Path $templatePath
    $wikiTraccsSitePageContentType = Get-PnPContentType -Connection $connection -Identity $wikiTraccsSitePageContentTypeName -ErrorAction SilentlyContinue
    if (-not $wikiTraccsSitePageContentType) 
    {
        Write-Error "Cannot find WikiTraccs content type even after provisioning it"
    }
    
    Add-PnPContentTypeToList -List $sitePagesLib -ContentType $wikiTraccsSitePageContentType -Connection $connection
    $wikiTraccsSitePageContentTypeOnList = Get-PnPContentType -List $sitePagesLib -Identity $wikiTraccsSitePageContentTypeName -Connection $connection -ErrorAction SilentlyContinue
    if (-not $wikiTraccsSitePageContentTypeOnList) 
    {
        Write-Error "Cannot find WikiTraccs content type on list even after adding it"
    }
}

$existingApps = Get-PnPApp -Connection $connection -Scope Tenant
$wikiPakkApp = $existingApps | Where-Object { $_.Title -eq "WikiTraccs WikiPakk"}
if (-not $wikiPakkApp)
{
    Write-Error "Cannot find WikiPakk app in tenant - get it via https://www.wikipakk.com; it needs to be installed to the SharePoint tenant app catalog"
}

# this installs the app and creates the hidden hierarchy list
Install-PnPApp -Scope Tenant -Identity $wikiPakkApp -Connection $connection -Wait -Verbose -ErrorAction SilentlyContinue

$pageIdMappingOldToNew = @{}


function DeleteAllPagesExceptHome()
{
    $pageListItems = Get-PnPListItem -List "SitePages" -Connection $connection
    foreach ($pageListItem in $pageListItems)
    {
        $pageName = $pageListItem.FieldValues["FileLeafRef"]
        #$pageId = $pageListItem.Id
#        $pageCtId = $pageListItem.FieldValues["ContentTypeId"]
 
        # leave this to only delete "migrated" pages
        # if ($pageCtId.StringValue -ne $wikiTraccsSitePageContentTypeOnList.StringId)
        # {
        #     Write-Host "$($pageName) - Keeping"
        #     continue
        # }

        $pageListItem.FieldValues["ContentType"]
        if ($pageName -like "*Home*")
        {
            Write-Host "$($pageName) - Keeping"
            continue;
        }

        Write-Host "$($pageName) - Removing"
        $null = Remove-PnPPage $pageName -Force:$true -Recycle:$false -Connection $connection
    }
}

function DeleteAllHierarchyListItems()
{
    Write-Host "Removing hierarchy list items"
    $pageListItems = Get-PnPListItem -List "Lists/WikiTraccsPageTree" -Connection $connection
    foreach ($pageListItem in $pageListItems)
    {
        Write-Host "$($pageListItem.Id) - Removing"
        Remove-PnPListItem -List "Lists/WikiTraccsPageTree" -Identity $pageListItem.Id -Force -Recycle:$false -Connection $connection
    }
}

function CreateAndUpdatePages()
{
    $pagesLibCsvData = Import-Csv -Path $pagesLibCsvFilePath
    if ($pagesLibCsvData) {
        foreach ($row in $pagesLibCsvData) {
            if (-not $row.PageId -or -not $row.Name)
            {
                # skip empty lines
                continue;
            }
            if (-not $row.Name.EndsWith(".aspx"))
            {
                $row.Name = $row.Name + ".aspx"
            }

            Write-Host "$($row.Name) - Checking existence"
            $page = Get-PnPPage -Identity $row.Name -ErrorAction SilentlyContinue -Connection $connection
            if (-not $page)
            {
                if ($row.ForeignId -and $row.ForeignParentId)
                {
                    Write-Host "$($row.Name) - Creating migrated Confluence page..."
                    # this is a migrated Confluence page
                    $page = Add-PnPPage -Name $row.Name -ContentType $wikiTraccsSitePageContentType -Publish -Title $row.CfTitle -Connection $connection
                } else 
                {
                    Write-Host "$($row.Name) - Creating vanilla SharePoint page..."
                    # this is a vanilla SharePoint page
                    $page = Add-PnPPage -Name $row.Name -Publish -Title $row.Name -Connection $connection
                }
            }
            if ($page)
            {
                if ($row.ForeignId -and $row.ForeignParentId)
                {
                    Write-Host "$($row.Name) - Setting Confluence metadata..."
                    $null = Set-PnPListItem -List "SitePages" -Identity $page.PageId -Values @{
                        "WT_In_CfContentId" = $row.ForeignId
                        "WT_In_CfParentId" = $row.ForeignParentId
                        "WT_In_CfTitle" = $row.CfTitle
                        "WT_In_CfSpaceKey" = $row.CfSpaceKey
                        "WT_In_CfSiblingOrder" = $row.Order
                    } -Connection $connection
                }
                $page.Publish()
            }
            $pageIdMappingOldToNew[$row.PageId] = $page.PageId
            $pageIdMappingOldToNew
            Write-Host "$($row.Name) - Done"
        }
    } else {
        Write-Host "No pages data to process."
    }
}

function CreateAndUpdateHierarchyListItems()
{
    $hierarchyListPath = "Lists/WikiTraccsPageTree"
    $hierarchyList = Get-PnPList $hierarchyListPath -Connection $connection -ErrorAction SilentlyContinue
    if (-not $hierarchyList)
    {
        Write-Error "Cannot find list $hierarchyListPath; this should normally be created when adding the WikiPakk app to the site; check this"
    }
    $hierarchyListCsvData = Import-Csv -Path $hierarchyListCsFilePath
    if ($hierarchyListCsvData) {
        foreach ($row in $hierarchyListCsvData) {

            # the IDs are different compared to the original site; need to update those
            $pageId = $pageIdMappingOldToNew[$row.PageId]# ?? $row.PageId
            $parentPageId = $null
            if ($row.ParentPageId -eq "0")
            {
                $parentPageId = 0
            } else 
            {
                $parentPageId = $pageIdMappingOldToNew[$row.ParentPageId]# ?? $row.ParentPageId
            }

            if (-not $pageId)
            {
                Write-Host "Skipping row because mapping for page ID cannot be found: $row"
                #continue;
            }
            
            Write-Host "$($row.PageId) - Checking existence..."
            $existingItem = Get-PnPListItem -List $hierarchyList -Query "<View><Query><Where><Eq><FieldRef Name='WtPId'/><Value Type='Number'>$pageId</Value></Eq></Where></Query></View>" -Connection $connection
            if (-not $existingItem)
            {
                $values = @{
                    "WtPId" = $pageId
                    "WtPPId" = $parentPageId
                }
                Write-Host "$($row.PageId) - Adding..."
                $null = Add-PnPListItem -List $hierarchyList -Values $values -Connection $connection
            } else {
                Write-Host "$($row.PageId) - Exists"
            }
            Write-Host "$($row.PageId) - Done"
        }
    } else {
        Write-Host "No pages data to process."
    }
}

function CreateChildPagesForConfluencePage([string]$cfParentId, [int]$numberofPages, [int]$cfIdStart, [int]$idStep)
{
    # PageId, ParentPageId, ForeignId, ForeignParentId, Rank, Source, Order, SortModeForChildren, Name, CfSpaceKey, CfTitle
    
    $pageIds = @()
    for ($i = 0; $i -lt $numberOfPages; $i++)
    {
        $pageId = $cfIdStart + $i * $idStep
        $name = "cf-page-$pageId.aspx"
        $title = "CF Page $pageId"
        $row = [PSCustomObject]@{
            PageId = $pageId
            ParentPageId = -1
            ForeignId = $pageId
            ForeignParentId = $cfParentId
            Rank = $null
            Source = $null
            Order = $null
            SortModeForChildren = $null
            Name = $name
            CfSpaceKey = "DUMMY"
            CfTitle = $title

        }
        $pageIds += $row
    }

    $pageIds | Export-Csv -Path "sitepages-lib-partial.csv" -NoTypeInformation -Encoding UTF8 -Append
    return $pageIds
}

function CreateVanillaPages([int]$parentPageId, [int]$numberofPages, [int]$idStart, [int]$idStep)
{
    # PageId, ParentPageId, ForeignId, ForeignParentId, Rank, Source, Order, SortModeForChildren, Name, CfSpaceKey, CfTitle
    $pageIds = @()
    $hierarchyListRows = @()
    for ($i = 0; $i -lt $numberOfPages; $i++)
    {
        $pageId = $idStart + $i * $idStep
        $name = "vanilla-page-$pageId.aspx"
        #$title = "Vanilla Page $pageId"
        $row = [PSCustomObject]@{
            PageId = $pageId
            ParentPageId = -1
            ForeignId = $null
            ForeignParentId = $null
            Rank = $null
            Source = $null
            Order = $null
            SortModeForChildren = $null
            Name = $name
            CfSpaceKey = $null
            CfTitle = $null

        }
        $pageIds += $row

        if ($parentPageId -ne -1)
        {
            #PageId, ParentPageId, ForeignId, ForeignParentId, Rank, Source, Order, SortModeForChildren            
            $hierarchyListRow = [PSCustomObject]@{
                PageId = $pageId
                ParentPageId = $parentPageId
                ForeignId = $null
                ForeignParentId = $null
                Rank = $null
                Source = $null
                Order = $null
                SortModeForChildren = $null
            }
            $hierarchyListRows += $hierarchyListRow
        }
    }

    $pageIds | Export-Csv -Path "sitepages-lib-partial.csv" -NoTypeInformation -Encoding UTF8 -Append
    $hierarchyListRows | Export-Csv -Path "hierarchy-list-partial.csv" -NoTypeInformation -Encoding UTF8 -Append
    return $pageIds
}

function CreateHierarchyListEntries([int]$parentId, [int[]]$childIds)
{
    # PageId, ParentPageId, ForeignId, ForeignParentId, Rank, Source, Order, SortModeForChildren, Name, CfSpaceKey, CfTitle
    
    $hierarchyListRows = @()
    foreach ($childId in $childIds)
    {
        #PageId, ParentPageId, ForeignId, ForeignParentId, Rank, Source, Order, SortModeForChildren            
        $hierarchyListRow = [PSCustomObject]@{
            PageId = $childId
            ParentPageId = $parentId
            ForeignId = $null
            ForeignParentId = $null
            Rank = $null
            Source = $null
            Order = $null
            SortModeForChildren = $null
        }
        $hierarchyListRows += $hierarchyListRow
            
    }

    $hierarchyListRows | Export-Csv -Path "hierarchy-list-partial.csv" -NoTypeInformation -Encoding UTF8 -Append
    return $hierarchyListRows
}

function CreateTestCsv()
{
    $numberOfRoots = 12
    $numberOfChildren = 10
    $numberOfGrandchildren = 8
    # root pages: 100000, 110000, 120000...
    $rootPages = CreateChildPagesForConfluencePage -cfParentId "0" -numberofPages $numberOfRoots -cfIdStart 100000 -idStep 10000
    $rootPageIds = $rootPages | Select-Object -ExpandProperty PageId

    $childPages = @()
    $grandChildPages = @()
    $pagesToRelocate = @()
    foreach ($rootPageId in $rootPageIds)
    {
        $childPages = CreateChildPagesForConfluencePage -cfParentId $rootPageId.ToString() -numberofPages $numberOfChildren -cfIdStart ($rootPageId+1000) -idStep 1000
        # move some pages from every child page collection
        $pagesToRelocate += ($childPages | Select-Object -First 1)
        $pagesToRelocate += ($childPages | Select-Object -Last 1)

        $childPageIds = $childPages | Select-Object -ExpandProperty PageId
        foreach ($childPageId in $childPageIds)
        {
            $grandChildPages = CreateChildPagesForConfluencePage -cfParentId $childPageId.ToString() -numberofPages $numberOfGrandchildren -cfIdStart ($childPageId+100) -idStep 100
        }
    }

    # vanilla root pages: 200000, 210000, 220000...
    $vanillaRootPages = CreateVanillaPages -numberofPages $numberOfRoots -idStart 200000 -idStep 10000
    $vanillaRootPageIds = $vanillaRootPages | Select-Object -ExpandProperty PageId
    # now some "manually placed" vanilla child pages
    foreach ($vanillaRootPageId in $vanillaRootPageIds)
    {
        $childPages = CreateVanillaPages -parentPageId $vanillaRootPageId -numberofPages $numberOfChildren -idStart ($vanillaRootPageId+1000) -idStep 1000

        # move some pages from every child page collection
        $pagesToRelocate += ($childPages | Select-Object -First 1)
        $pagesToRelocate += ($childPages | Select-Object -Last 1)

        $childPageIds = $childPages | Select-Object -ExpandProperty PageId
        foreach ($childPageId in $childPageIds)
        {
            $grandChildPages = CreateVanillaPages -parentPageId $childPageId.ToString() -numberofPages $numberOfGrandchildren -idStart ($childPageId+100) -idStep 100
        }
    }

    # now relocate some pages
    CreateHierarchyListEntries -parentId $vanillaRootPages[0].PageId -childIds ($pagesToRelocate | Select-Object -ExpandProperty PageId)
}

# use this to create new test data files based on changed parameters above
#CreateTestCsv

# delete all existing pages and hierarchy list items
DeleteAllHierarchyListItems
DeleteAllPagesExceptHome
# create new pages and hierarchy list items based on CSV file content - this will take a while
CreateAndUpdatePages
CreateAndUpdateHierarchyListItems