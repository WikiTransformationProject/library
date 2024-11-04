<#
    This script lists all sites that had WikiPakk added. It iterates all sites and checks all of them for WikiPakk.

    After checking all the prerequisites below and configuring all settings, simply run the script.
    
    PREREQUISITE: POWERSHELL 7

        Make sure to use PowerShell 7.
        Note: this script runs on Windows and Linux thanks to PowerShell 7.
    
    PREREQUISITE: INSTALL MODULE "PnP.PowerShell"

        Make sure to install the module PnP.PowerShell: 
        
            Install-Module PnP.PowerShell -Scope CurrentUser

    PREREQUISITE: CERTIFICATE FOR AUTH WITH ENTRA ID

        Authentication with Entra ID requires a (self-signed) certificate. Create that so that you have a .pfx and .cer file.

        Sample: How to create self-signed certificate on Linux:
            
            openssl req -x509 -sha256 -days 365 -nodes -out cert.crt -keyout cert.key -subj "/CN=www.contoso.com"
            openssl pkcs12 -export -out cert.pfx -inkey cert.key -in cert.crt
        
        Note: On Windows you can use the New-SelfSignedCertificate cmdlet

    PREREQUISITE: ENTRA ID APP REGISTRATION

        The script needs an Entra ID application registration.
        The application registration needs to grant Sites.FullControl.All permissions on the Microsoft Graph and on SharePoint.
        The permissions need to be APPLICATION permissions (NOT delegated).
        Upload the .cer certificate file to your entra app reg.

    PREREQUISITE: PASSWORD FILE

        The certificate is protected with a password. The script expects this password to be in a file named ".password".
        Create that file. Put the password in there. Or adjust the script.

    PREREQUISITE: CONFIGURE SCRIPT:

        $tenantAdminUrl
        $tenant
        $clientId
        $certificatePath
#>

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

# v--------CONFIGURE THOSE========
$tenantAdminUrl = "https://contoso-admin.sharepoint.com"
$tenant = "contoso.onmicrosoft.com"
# note: app need application permissions Sites.FullControl.All Graph and SharePoint permissions to iterate over all sites
$clientId = "0a7c32d1-fdd2-4389-b49d-910cfccfc96b"
$certificatePath = Join-Path "." "cert.pfx"
# ========CONFIGURATION END========

# note: the file .password has to exist and contain the password
$certificatePassword =  Get-Content ".password" -Raw | ConvertTo-SecureString -AsPlainText -Force

# need to connect to admin site to get a list of all sites
Connect-PnPOnline -Url $tenantAdminUrl -ClientId $clientId -Tenant $tenant -CertificatePath $certificatePath -CertificatePassword $certificatePassword
$web = Get-PnPWeb
if (-not $web)
{
    throw "Could connect to SharePoint admin site"
}

$foundUrls = @()
$allSiteUrls = Get-PnPTenantSite | Select-Object -ExpandProperty Url

Disconnect-PnPOnline
foreach ($siteUrl in $allSiteUrls)
{
    Write-Host "Checking site $siteUrl..." -ForegroundColor DarkGray -BackgroundColor Black
    $siteCon = $null
    $siteCon = Connect-PnPOnline -Url $siteUrl -ClientId $clientId -Tenant $tenant -CertificatePath $certificatePath -CertificatePassword $certificatePassword -ReturnConnection

    $web = Get-PnPWeb -Includes ServerRelativeUrl -Connection $siteCon
    if (-not $web)
    {
        throw "Failed to access site $siteUrl, which should not happen if the app registration has indeed full control permission on all sites"
    }

    $wikiPakkHierarchyList = Get-PnPList "DONOTMODIFY WikiTraccs Page Tree Data" -Connection $siteCon -ErrorAction SilentlyContinue
    if ($wikiPakkHierarchyList)
    {
        Write-Host "Found WikiPakk in site $siteUrl" -ForegroundColor Green -BackgroundColor Black

        # need to have Modified indexed to efficiently query for the most recently modified item
        $fieldInfo = Get-PnPField -List $wikiPakkHierarchyList -Identity "Modified" -Includes Indexed -Connection $siteCon
        if (-not $fieldInfo.Indexed)
        {
            Write-Host "Making Modified column indexed..." -ForegroundColor DarkGray -BackgroundColor Black
            $fieldInfo.Indexed = $true
            $fieldInfo.Update()
            (Get-PnPContext -Connection $siteCon).ExecuteQuery()
            Write-Host "DONE: Making Modified column indexed" -ForegroundColor DarkGray -BackgroundColor Black
        } else 
        {
            Write-Host "Modified column is indexed, good" -ForegroundColor DarkGray -BackgroundColor Black
        }

        $maxModifiedDate = [DateTime]::MinValue
        $lastEditor = ""
        
        # getting the most recently modified element works via REST API even when exceeding the list view threshold; CAML doesn't work
        $apiUrl = '/_api/web/lists/GetByTitle(''DONOTMODIFY WikiTraccs Page Tree Data'')/items?$select=ID&$orderby=Modified desc&$top=1'
        $response = Invoke-PnPSPRestMethod -Url $apiUrl -Method Get -Connection $siteCon
        
        $latestItem = $null
        if ($response.value.Count -eq 1)
        {
            $item = $response.value[0]
            $itemId = $item.ID
            Write-Host "Identified item $itemId as being last modified" -ForegroundColor DarkGray -BackgroundColor Black

            $latestItem = Get-PnPListItem -List $wikiPakkHierarchyList -Id $itemId -Connection $siteCon
        }
        if ($latestItem)
        {
            $maxModifiedDate = $latestItem["Modified"]
            $lastEditor = $latestItem["Editor"].Email

        } else
        # note: the following code iterates the list items rather than getting the most recently modified one via REST; fallback if REST doesn't work as expected
        # note2: this will also be triggered if there are no items in the list, but so be it
        {        
            $listItems = Get-PnPListItem -List $wikiPakkHierarchyList -PageSize 4999 -Connection $siteCon
            Write-Host "Checking $($listItems.Count) list items to determine last modified date and last editor..." -ForegroundColor Green -BackgroundColor Black
            $counter = 0
            foreach ($listItem in $listItems)
            {
                $counter++
                Write-Host "$counter " -NoNewline -ForegroundColor DarkGray -BackgroundColor Black
                $item = Get-PnPListItem -List $wikiPakkHierarchyList -Id $listItem.Id -Fields Modified,Editor -Connection $siteCon
                if ($item["Modified"] -gt $maxModifiedDate)
                {
                    $maxModifiedDate = $item["Modified"]
                    $lastEditor = $item["Editor"].Email
                }
            }
        }
        Write-Host ""
        Write-Host "...page tree was last MODIFIED on $($maxModifiedDate.ToString("o")) by $($lastEditor)" -ForegroundColor Green -BackgroundColor Black
        $foundUrls += @{
            SiteUrl = $siteUrl
            MaxModifiedDate = $maxModifiedDate
            LastEditor = $lastEditor
        }
    }
}
Write-Host ""
Write-Host "DONE"
Write-Host "Summary (Site URL, last modified date, last editor):" -ForegroundColor White -BackgroundColor Black
Write-Host "----------------------------------------------------------" -ForegroundColor White -BackgroundColor Black
foreach ($foundUrl in $foundUrls)
{
    Write-Host  "$($foundUrl.SiteUrl), $($foundUrl.MaxModifiedDate.ToString("o")), $($foundUrl.LastEditor)" -ForegroundColor Green -BackgroundColor Black
}
Write-Host ""
Write-Host "$($foundUrls.Count) sites with WikiPakk" -ForegroundColor Green -BackgroundColor Black
Write-Host ""
Write-Host "IMPORTANT: Above statistics list MODIFICATIONS to the WikiPakk page tree (reordering); this does NOT cover READ-ONLY usage" -ForegroundColor Yellow -BackgroundColor Black