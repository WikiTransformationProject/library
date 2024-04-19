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
            $pageIdMappingOldToNew.Count
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
                Write-Host "$($row.PageId) - Exists, Updating"
                $values = @{
                    "WtPId" = $pageId
                    "WtPPId" = $parentPageId
                }
                Write-Host "$($row.PageId) - Adding..."
                $null = Set-PnPListItem -Identity $existingItem -List $hierarchyList -Values $values -Connection $connection
            }
            Write-Host "$($row.PageId) - Done"
        }
    } else {
        Write-Host "No pages data to process."
    }
}

function CreateChildPagesForConfluencePage([string]$cfParentId, [long]$numberofPages, [long]$cfIdStart, [long]$idStep)
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

function CreateVanillaPages([long]$parentPageId, [long]$numberofPages, [long]$idStart, [long]$idStep)
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

function CreateHierarchyListEntries([long]$parentId, [long[]]$childIds)
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
    $numberOfRoots = 11
    $numberOfMigChildren = 7
    # little bit more vanilla children to push hierarchy list beyong 5000 elements
    $numberOfVanillaChildren = 12
    $numberOfGrandchildren = 9
    $numberOfLeaves = 3

    $rootPageIdStartMultiplier   = 100000000000000
    $rootPageIdStep              = 1000000000000
    $childPageIdStartOffset      = 10000000000
    $childPageIdStep             = 100000000
    $grandchildPageIdStartOffset = 1000000
    $grandchildPageIdStep        = 10000
    $leafPageIdStartOffset       = 100
    $leafPageIdStep              = 1

    # root pages: 10000000, 10100000, 10200000...
    $rootPages = CreateChildPagesForConfluencePage -cfParentId "0" -numberofPages $numberOfRoots -cfIdStart (1*$rootPageIdStartMultiplier) -idStep $rootPageIdStep
    $rootPageIds = $rootPages | Select-Object -ExpandProperty PageId

    $childPages = @()
    $grandchildPages = @()
    $childPagesToRelocate = @()
    $leavesToRelocate = @()
    foreach ($rootPageId in $rootPageIds)
    {
        $childPages = CreateChildPagesForConfluencePage -cfParentId $rootPageId.ToString() -numberofPages $numberOfMigChildren -cfIdStart ($rootPageId+$childPageIdStartOffset) -idStep $childPageIdStep
        # move some pages from every child page collection
        $childPagesToRelocate += ($childPages | Select-Object -First 1)
        $childPagesToRelocate += ($childPages | Select-Object -Last 1)

        $childPageIds = $childPages | Select-Object -ExpandProperty PageId
        foreach ($childPageId in $childPageIds)
        {
            $grandchildPages = CreateChildPagesForConfluencePage -cfParentId $childPageId.ToString() -numberofPages $numberOfGrandchildren -cfIdStart ($childPageId+$grandchildPageIdStartOffset) -idStep $grandchildPageIdStep

            # move some pages from every child page collection
            $leavesToRelocate += ($grandchildPages | Select-Object -First 1)
            $leavesToRelocate += ($grandchildPages | Select-Object -Last 1)

            $grandchildPageIds = $grandchildPages | Select-Object -ExpandProperty PageId
            foreach ($grandchildPageId in $grandchildPageIds)
            {
                CreateChildPagesForConfluencePage -cfParentId $grandchildPageId.ToString() -numberofPages $numberOfLeaves -cfIdStart ($grandchildPageId+$leafPageIdStartOffset) -idStep $leafPageIdStep
            }
        }
    }

    # vanilla root pages: 20000000, 20100000, 20200000...
    $vanillaRootPages = CreateVanillaPages -numberofPages $numberOfRoots -idStart (2*$rootPageIdStartMultiplier) -idStep $rootPageIdStep
    $vanillaRootPageIds = $vanillaRootPages | Select-Object -ExpandProperty PageId
    # now some "manually placed" vanilla child pages
    foreach ($vanillaRootPageId in $vanillaRootPageIds)
    {
        $childPages = CreateVanillaPages -parentPageId $vanillaRootPageId -numberofPages $numberOfVanillaChildren -idStart ($vanillaRootPageId+$childPageIdStartOffset) -idStep $childPageIdStep

        # move some pages from every child page collection
        $childPagesToRelocate += ($childPages | Select-Object -First 1)
        $childPagesToRelocate += ($childPages | Select-Object -Last 1)

        $childPageIds = $childPages | Select-Object -ExpandProperty PageId
        foreach ($childPageId in $childPageIds)
        {
            $grandchildPages = CreateVanillaPages -parentPageId $childPageId.ToString() -numberofPages $numberOfGrandchildren -idStart ($childPageId+$grandchildPageIdStartOffset) -idStep $grandchildPageIdStep

            # move some pages from every child page collection
            $leavesToRelocate += ($grandchildPages | Select-Object -First 1)
            $leavesToRelocate += ($grandchildPages | Select-Object -Last 1)

            $grandchildPageIds = $grandchildPages | Select-Object -ExpandProperty PageId
            foreach ($grandchildPageId in $grandchildPageIds)
            {
                CreateVanillaPages -parentPageId $grandchildPageId.ToString() -numberofPages $numberOfLeaves -idStart ($grandchildPageId+$leafPageIdStartOffset) -idStep $leafPageIdStep
            }
        }
    }

    # now relocate some pages; note: this creates duplicates in the CSV, but later it will just update the existing item with the last value from the CSV
    CreateHierarchyListEntries -parentId $vanillaRootPages[0].PageId -childIds ($childPagesToRelocate | Select-Object -ExpandProperty PageId)
    CreateHierarchyListEntries -parentId $vanillaRootPages[1].PageId -childIds ($leavesToRelocate | Select-Object -ExpandProperty PageId)
}

# use this to create new test data files based on changed parameters above
#CreateTestCsv

# delete all existing pages and hierarchy list items
#DeleteAllHierarchyListItems
#DeleteAllPagesExceptHome

# create new pages and hierarchy list items based on CSV file content - this will take a while
CreateAndUpdatePages
CreateAndUpdateHierarchyListItems