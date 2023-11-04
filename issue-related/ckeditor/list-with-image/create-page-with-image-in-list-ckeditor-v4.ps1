#Install-Module PnP.PowerShell -Scope CurrentUser
Import-Module PnP.PowerShell

####################################################################
# Configure page URL here
####################################################################
$siteUrl = "https://contoso.sharepoint.com/sites/test"
####################################################################




# image file, will be searched in current directory
$imageFilename = "pnp-parker.png"
# filename of modern page to be created in SharePoint
$pageName = "repro-ckeditor-upgrade-breaks-image-positioning-2.aspx"

# ensure image exists and get path
$item = Get-Item $imageFilename -ErrorAction Stop

if (!$connection -or $connection.Url -ne $siteUrl)
{
    $connection = $null
    # connect to SharePoint
    $connection = Connect-PnPOnline $siteUrl -Interactive -ReturnConnection
}

if (!$connection) {
    exit
}

# ensure Site Assets library exist as upload target for image
$web = Get-PnPProperty -ClientObject (Get-PnPSite -Connection $connection) -Property RootWeb -Connection $connection
$serverRelativeWebUrl = Get-PnPProperty -ClientObject $web -Property ServerRelativeUrl -Connection $connection
$lib = $web.Lists.EnsureSiteAssetsLibrary()
Invoke-PnPQuery -Connection $connection
$folderName = (Get-PnPProperty $lib -Property RootFolder -Connection $connection).Name

$file = $null
# upload image to Site Assets library
$file = Add-PnPFile -Path $item.FullName -Folder $folderName -Connection $connection
if (!$file) {
    exit
}

$page = $null
# create test page
$page = Add-PnPPage -Name $pageName -LayoutType Article -Publish -Connection $connection
if (!$page) {
    exit
}

$html = @"
<div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="{&quot;webPartId&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;rteInstanceId&quot;:&quot;fcdc347c-a460-4e7c-9065-bba95875a479&quot;,&quot;addedFromPersistedData&quot;:true,&quot;reservedHeight&quot;:0,&quot;reservedWidth&quot;:0,&quot;controlType&quot;:3,&quot;id&quot;:&quot;a94e6edf-8fe7-4c60-8c37-97b36d50708c&quot;,&quot;position&quot;:{&quot;controlIndex&quot;:1,&quot;zoneIndex&quot;:1,&quot;sectionIndex&quot;:1,&quot;sectionFactor&quot;:12,&quot;layoutIndex&quot;:1},&quot;emphasis&quot;:{&quot;zoneEmphasis&quot;:0},&quot;zoneGroupMetadata&quot;:null}">
        <div data-sp-webpart="" data-sp-webpartdataversion="1.9"
            data-sp-webpartdata="{&quot;id&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;instanceId&quot;:&quot;a94e6edf-8fe7-4c60-8c37-97b36d50708c&quot;,&quot;title&quot;:&quot;Image&quot;,&quot;description&quot;:&quot;Image&quot;,&quot;dataVersion&quot;:&quot;1.9&quot;,&quot;properties&quot;:{&quot;id&quot;:&quot;8e79a51b-c248-485f-9f06-76b136370222&quot;,&quot;isInlineImage&quot;:true,&quot;imageSourceType&quot;:2,&quot;altText&quot;:&quot;&quot;,&quot;linkUrl&quot;:&quot;&quot;,&quot;overlayText&quot;:&quot;&quot;,&quot;fileName&quot;:&quot;$imageFilename&quot;,&quot;siteId&quot;:&quot;cef85835-105a-4fc2-8c71-c0e9af03a152&quot;,&quot;webId&quot;:&quot;7d0da7b6-ccec-4b11-adf3-e15fdff55c4d&quot;,&quot;listId&quot;:&quot;b88ac73b-c39c-45ec-8d65-3ed3e6f09ea8&quot;,&quot;uniqueId&quot;:&quot;36c0e722-ad6e-4b9c-91e5-0f2c40b77fd9&quot;,&quot;imgWidth&quot;:1080,&quot;imgHeight&quot;:819,&quot;alignment&quot;:&quot;Left&quot;,&quot;fixAspectRatio&quot;:true,&quot;resizeCoefficient&quot;:0.2769360269360269,&quot;resizeDesiredWidth&quot;:329},&quot;dynamicDataPaths&quot;:{},&quot;dynamicDataValues&quot;:{},&quot;serverProcessedContent&quot;:{&quot;imageSources&quot;:{&quot;imageSource&quot;:&quot;$serverRelativeWebUrl/$folderName/$imageFilename&quot;}}}">
            <div data-sp-componentid="d1d91016-032f-456d-98a4-721247c305e8"></div>
            <div data-sp-htmlproperties=""><img data-sp-prop-name="imageSource"
                    src="$serverRelativeWebUrl/$folderName/$imageFilename"></img></div>
        </div>
    </div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="{&quot;editorType&quot;:&quot;CKEditor&quot;,&quot;controlType&quot;:4,&quot;id&quot;:&quot;fcdc347c-a460-4e7c-9065-bba95875a479&quot;,&quot;position&quot;:{&quot;controlIndex&quot;:5,&quot;zoneIndex&quot;:1,&quot;sectionIndex&quot;:1,&quot;sectionFactor&quot;:12,&quot;layoutIndex&quot;:1},&quot;emphasis&quot;:{&quot;zoneEmphasis&quot;:0},&quot;zoneGroupMetadata&quot;:null}">
        <div data-sp-rte="">
            <p>Text before</p>
            <ol>
                <li>First list item</li>
                <li>Second list item with image, indentation level is 1:
                    <div tabindex="0" data-cke-widget-wrapper="1" data-cke-filter="off"
                        class="cke_widget_wrapper cke_widget_block cke_widget_inlineimage cke_widget_wrapper_webPartInRteInlineImage cke_widget_wrapper_webPartInRte cke_widget_wrapper_webPartInRteAlignLeft"
                        data-cke-display-name="div" data-cke-widget-id="0" role="region"
                        aria-label="Inline image in RTE. Use Alt + F11 to go to toolbar. Use Alt + P to open the property pane.">
                        <div data-webpart-id="image"
                            class="webPartInRte webPartInRteInlineImage cke_widget_element webPartInRteAlignLeft"
                            data-cke-widget-data="%7B%22classes%22%3A%7B%22webPartInRteInlineImage%22%3A1%2C%22webPartInRteAlignLeft%22%3A1%2C%22webPartInRte%22%3A1%7D%7D"
                            data-cke-widget-upcasted="1" data-cke-widget-keep-attr="0" data-widget="inlineimage"
                            data-instance-id="a94e6edf-8fe7-4c60-8c37-97b36d50708c" title="" data-indentation-levels="1"></div>
                </div>
            </li>
            <li>
                Third list item
            </li>
            </ol>
            <p>Text after</p>
        </div>
    </div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="{&quot;controlType&quot;:0,&quot;pageSettingsSlice&quot;:{&quot;isDefaultDescription&quot;:true,&quot;isDefaultThumbnail&quot;:true,&quot;isSpellCheckEnabled&quot;:true,&quot;globalRichTextStylingVersion&quot;:1,&quot;rtePageSettings&quot;:{&quot;contentVersion&quot;:4},&quot;isEmailReady&quot;:false}}">
    </div>
</div>
"@
# set page content
Set-PnPListItem -List "SitePages" -Identity $page.PageId -Values @{"CanvasContent1" = $html } -Connection $connection
Invoke-PnPQuery -Connection $connection