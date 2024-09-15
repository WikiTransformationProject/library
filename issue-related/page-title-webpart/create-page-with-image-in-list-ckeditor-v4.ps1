#Install-Module PnP.PowerShell -Scope CurrentUser
Import-Module PnP.PowerShell

####################################################################
# Configure page URL here
####################################################################
$siteUrl = "https://contoso.sharepoint.com/sites/test"
####################################################################


$clientIdBecauseMicrosoftDoesNotProvideOneAnymore = "d62ae113-5a68-4df9-b0f9-702439431eef"

# filename of modern page to be created in SharePoint
$pageName = "repro-page-title-webpart-is-missing-topic-header.aspx"

if (!$connection -or $connection.Url -ne $siteUrl)
{
    $connection = $null
    # connect to SharePoint
    $connection = Connect-PnPOnline $siteUrl -Interactive -ClientId $clientIdBecauseMicrosoftDoesNotProvideOneAnymore -ReturnConnection
}

if (!$connection) {
    exit
}


    # Note: this can be used to get a page with PageTitle web part content to look at content and fields:
    # $templatePageWithPageTitleWebPart = Get-PnPPage "template.aspx" -Connection $connection
    # $spItemId = $templatePageWithPageTitleWebPart.PageId
    # $templateListItem = Get-PnPListItem -List "Site Pages" -Id $spItemId -Fields @("Id","Title","CanvasContent1","GUID","_TopicHeader","LayoutWebpartsContent") -Connection $connection
    # $templateListItem["_TopicHeader"]
    # $templateListItem["LayoutWebpartsContent"]
    # $canvasContent1 = $templateListItem["CanvasContent1"]


$topicHeaderText = "Missing Topic Header Picard"
$contentVersion = "4"

$html = @"
<div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="&#123;&quot;position&quot;&#58;&#123;&quot;layoutIndex&quot;&#58;1,&quot;zoneIndex&quot;&#58;1,&quot;zoneId&quot;&#58;&quot;fed1887c-145d-42fc-a459-ffc27f0cd3fa&quot;,&quot;sectionIndex&quot;&#58;1,&quot;sectionFactor&quot;&#58;0,&quot;controlIndex&quot;&#58;1&#125;,&quot;emphasis&quot;&#58;&#123;&quot;zoneEmphasis&quot;&#58;0&#125;,&quot;id&quot;&#58;&quot;2cb8b5b5-f6dd-47ca-8740-8acc94e95714&quot;,&quot;controlType&quot;&#58;3,&quot;addedFromPersistedData&quot;&#58;true,&quot;isFromSectionTemplate&quot;&#58;false,&quot;webPartId&quot;&#58;&quot;cbe7b0a9-3504-44dd-a3a3-0e5cacd07788&quot;,&quot;reservedWidth&quot;&#58;1521,&quot;reservedHeight&quot;&#58;300&#125;">
        <div data-sp-webpart="" data-sp-webpartdataversion="1.5"
            data-sp-webpartdata="&#123;&quot;id&quot;&#58;&quot;cbe7b0a9-3504-44dd-a3a3-0e5cacd07788&quot;,&quot;instanceId&quot;&#58;&quot;2cb8b5b5-f6dd-47ca-8740-8acc94e95714&quot;,&quot;title&quot;&#58;&quot;Banner&quot;,&quot;audiences&quot;&#58;[],&quot;serverProcessedContent&quot;&#58;&#123;&quot;htmlStrings&quot;&#58;&#123;&#125;,&quot;searchablePlainTexts&quot;&#58;&#123;&#125;,&quot;imageSources&quot;&#58;&#123;&#125;,&quot;links&quot;&#58;&#123;&#125;&#125;,&quot;dataVersion&quot;&#58;&quot;1.5&quot;,&quot;properties&quot;&#58;&#123;&quot;title&quot;&#58;&quot;Template&quot;,&quot;imageSourceType&quot;&#58;4,&quot;layoutType&quot;&#58;&quot;Fade&quot;,&quot;textAlignment&quot;&#58;&quot;Left&quot;,&quot;showTopicHeader&quot;&#58;true,&quot;showPublishDate&quot;&#58;true,&quot;topicHeader&quot;&#58;&quot;$topicHeaderText&quot;,&quot;enableGradientEffect&quot;&#58;true,&quot;isDecorative&quot;&#58;true,&quot;isFullWidth&quot;&#58;true,&quot;authorByline&quot;&#58;[&quot;i&#58;0#.f|membership|admin@wikitransformationproject.onmicrosoft.com&quot;],&quot;authors&quot;&#58;[&#123;&quot;id&quot;&#58;&quot;i&#58;0#.f|membership|admin@wikitransformationproject.onmicrosoft.com&quot;,&quot;upn&quot;&#58;&quot;admin@wikitransformationproject.onmicrosoft.com&quot;,&quot;email&quot;&#58;&quot;admin@wikitransformationproject.onmicrosoft.com&quot;,&quot;name&quot;&#58;&quot;Heinrich Ulbricht&quot;,&quot;role&quot;&#58;&quot;&quot;&#125;]&#125;,&quot;containsDynamicDataSource&quot;&#58;false&#125;">
            <div data-sp-componentid="cbe7b0a9-3504-44dd-a3a3-0e5cacd07788"></div>
            <div data-sp-htmlproperties=""></div>
        </div>
    </div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="&#123;&quot;controlType&quot;&#58;0,&quot;pageSettingsSlice&quot;&#58;&#123;&quot;isDefaultDescription&quot;&#58;true,&quot;isDefaultThumbnail&quot;&#58;true,&quot;isSpellCheckEnabled&quot;&#58;true,&quot;globalRichTextStylingVersion&quot;&#58;1,&quot;rtePageSettings&quot;&#58;&#123;&quot;contentVersion&quot;&#58;$contentVersion&#125;,&quot;isEmailReady&quot;&#58;false&#125;&#125;"></div>
</div>

"@

$page = $null
$page = Get-PnPPage $pageName -Connection $connection -ErrorAction SilentlyContinue
if ($page)
{
    $page | Remove-PnPPage -Force -Connection $connection
}
# create test page
$page = Add-PnPPage -Name $pageName -LayoutType Article -Publish -Connection $connection
if (!$page) {
    exit
}

# set page content
Set-PnPListItem -List "SitePages" -Identity $page.PageId -Values @{"CanvasContent1" = $html; "_TopicHeader" = $topicHeaderText; "LayoutWebpartsContent" = "<div></div>" } -Connection $connection
Invoke-PnPQuery -Connection $connection