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

# v--------CONFIGURE THOSE========
$tenantAdminUrl = "https://contoso-admin.sharepoint.com"
$tenant = "contoso.onmicrosoft.com"
# note: app need application permissions Sites.FullControl.All Graph and SharePoint permissions to iterate over all sites
$clientId = "abba7a8a-5377-4d00-a0bc-f700f379b546"
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
        $foundUrls += $siteUrl
    }
}
Write-Host "DONE; Summary:"  -ForegroundColor White -BackgroundColor Black
$foundUrls
Write-Host "$($foundUrls.Count) sites with WikiPakk" -ForegroundColor Green -BackgroundColor Black