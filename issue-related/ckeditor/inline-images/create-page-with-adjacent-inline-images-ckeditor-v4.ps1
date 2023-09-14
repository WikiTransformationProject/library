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
$pageName = "imagetest3.aspx"

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
$web = Get-PnPWeb -Connection $connection
$serverRelativeWebUrl = $web.ServerRelativeUrl
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
        data-sp-controldata="{&quot;webPartId&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;rteInstanceId&quot;:&quot;fcdc347c-a460-4e7c-9065-bba95875a479&quot;,&quot;addedFromPersistedData&quot;:true,&quot;reservedHeight&quot;:0,&quot;reservedWidth&quot;:0,&quot;controlType&quot;:3,&quot;id&quot;:&quot;7c7f3c3c-f518-4d4c-b618-02c48eb5fccc&quot;,&quot;position&quot;:{&quot;controlIndex&quot;:2,&quot;zoneIndex&quot;:1,&quot;sectionIndex&quot;:1,&quot;sectionFactor&quot;:12,&quot;layoutIndex&quot;:1},&quot;emphasis&quot;:{&quot;zoneEmphasis&quot;:0},&quot;zoneGroupMetadata&quot;:null}">
        <div data-sp-webpart="" data-sp-webpartdataversion="1.9"
            data-sp-webpartdata="{&quot;id&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;instanceId&quot;:&quot;7c7f3c3c-f518-4d4c-b618-02c48eb5fccc&quot;,&quot;title&quot;:&quot;Image&quot;,&quot;description&quot;:&quot;Image&quot;,&quot;dataVersion&quot;:&quot;1.9&quot;,&quot;properties&quot;:{&quot;id&quot;:&quot;57b29cf3-35f1-48a4-b078-a56e5415e184&quot;,&quot;isInlineImage&quot;:true,&quot;imageSourceType&quot;:2,&quot;altText&quot;:&quot;&quot;,&quot;linkUrl&quot;:&quot;&quot;,&quot;overlayText&quot;:&quot;&quot;,&quot;fileName&quot;:&quot;$imageFilename&quot;,&quot;siteId&quot;:&quot;cef85835-105a-4fc2-8c71-c0e9af03a152&quot;,&quot;webId&quot;:&quot;7d0da7b6-ccec-4b11-adf3-e15fdff55c4d&quot;,&quot;listId&quot;:&quot;b88ac73b-c39c-45ec-8d65-3ed3e6f09ea8&quot;,&quot;uniqueId&quot;:&quot;15582c49-654e-455a-9440-587c6f2db92a&quot;,&quot;imgWidth&quot;:1080,&quot;imgHeight&quot;:819,&quot;alignment&quot;:&quot;Left&quot;,&quot;fixAspectRatio&quot;:true,&quot;resizeCoefficient&quot;:0.2769360269360269,&quot;resizeDesiredWidth&quot;:329},&quot;dynamicDataPaths&quot;:{},&quot;dynamicDataValues&quot;:{},&quot;serverProcessedContent&quot;:{&quot;imageSources&quot;:{&quot;imageSource&quot;:&quot;$serverRelativeWebUrl/$folderName/$imageFilename&quot;}}}">
            <div data-sp-componentid="d1d91016-032f-456d-98a4-721247c305e8"></div>
            <div data-sp-htmlproperties=""><img data-sp-prop-name="imageSource"
                    src="$serverRelativeWebUrl/$folderName/$imageFilename"></img></div>
        </div>
    </div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="{&quot;webPartId&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;rteInstanceId&quot;:&quot;fcdc347c-a460-4e7c-9065-bba95875a479&quot;,&quot;addedFromPersistedData&quot;:true,&quot;reservedHeight&quot;:0,&quot;reservedWidth&quot;:0,&quot;controlType&quot;:3,&quot;id&quot;:&quot;292dfedc-37ca-4613-8c24-5c83092de8fd&quot;,&quot;position&quot;:{&quot;controlIndex&quot;:3,&quot;zoneIndex&quot;:1,&quot;sectionIndex&quot;:1,&quot;sectionFactor&quot;:12,&quot;layoutIndex&quot;:1},&quot;emphasis&quot;:{&quot;zoneEmphasis&quot;:0},&quot;zoneGroupMetadata&quot;:null}">
        <div data-sp-webpart="" data-sp-webpartdataversion="1.9"
            data-sp-webpartdata="{&quot;id&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;instanceId&quot;:&quot;292dfedc-37ca-4613-8c24-5c83092de8fd&quot;,&quot;title&quot;:&quot;Image&quot;,&quot;description&quot;:&quot;Image&quot;,&quot;dataVersion&quot;:&quot;1.9&quot;,&quot;properties&quot;:{&quot;id&quot;:&quot;9a620998-fa1a-461f-9194-6d13efa17c62&quot;,&quot;isInlineImage&quot;:true,&quot;imageSourceType&quot;:2,&quot;altText&quot;:&quot;&quot;,&quot;linkUrl&quot;:&quot;&quot;,&quot;overlayText&quot;:&quot;&quot;,&quot;fileName&quot;:&quot;$imageFilename&quot;,&quot;siteId&quot;:&quot;cef85835-105a-4fc2-8c71-c0e9af03a152&quot;,&quot;webId&quot;:&quot;7d0da7b6-ccec-4b11-adf3-e15fdff55c4d&quot;,&quot;listId&quot;:&quot;b88ac73b-c39c-45ec-8d65-3ed3e6f09ea8&quot;,&quot;uniqueId&quot;:&quot;74cc6d9e-a0ef-473e-9671-a934a6eb57ff&quot;,&quot;imgWidth&quot;:1080,&quot;imgHeight&quot;:819,&quot;alignment&quot;:&quot;Right&quot;,&quot;fixAspectRatio&quot;:true,&quot;resizeCoefficient&quot;:0.2769360269360269,&quot;resizeDesiredWidth&quot;:329},&quot;dynamicDataPaths&quot;:{},&quot;dynamicDataValues&quot;:{},&quot;serverProcessedContent&quot;:{&quot;imageSources&quot;:{&quot;imageSource&quot;:&quot;$serverRelativeWebUrl/$folderName/$imageFilename&quot;}}}">
            <div data-sp-componentid="d1d91016-032f-456d-98a4-721247c305e8"></div>
            <div data-sp-htmlproperties=""><img data-sp-prop-name="imageSource"
                    src="$serverRelativeWebUrl/$folderName/$imageFilename"></img></div>
        </div>
    </div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="{&quot;webPartId&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;rteInstanceId&quot;:&quot;fcdc347c-a460-4e7c-9065-bba95875a479&quot;,&quot;addedFromPersistedData&quot;:true,&quot;reservedHeight&quot;:0,&quot;reservedWidth&quot;:0,&quot;controlType&quot;:3,&quot;id&quot;:&quot;2a41b9af-b37f-4650-80ab-58821073607e&quot;,&quot;position&quot;:{&quot;controlIndex&quot;:4,&quot;zoneIndex&quot;:1,&quot;sectionIndex&quot;:1,&quot;sectionFactor&quot;:12,&quot;layoutIndex&quot;:1},&quot;emphasis&quot;:{&quot;zoneEmphasis&quot;:0},&quot;zoneGroupMetadata&quot;:null}">
        <div data-sp-webpart="" data-sp-webpartdataversion="1.9"
            data-sp-webpartdata="{&quot;id&quot;:&quot;d1d91016-032f-456d-98a4-721247c305e8&quot;,&quot;instanceId&quot;:&quot;2a41b9af-b37f-4650-80ab-58821073607e&quot;,&quot;title&quot;:&quot;Image&quot;,&quot;description&quot;:&quot;Image&quot;,&quot;dataVersion&quot;:&quot;1.9&quot;,&quot;properties&quot;:{&quot;id&quot;:&quot;45791d81-70f8-4b0b-a869-ca9af5ec6884&quot;,&quot;isInlineImage&quot;:true,&quot;imageSourceType&quot;:2,&quot;altText&quot;:&quot;&quot;,&quot;linkUrl&quot;:&quot;&quot;,&quot;overlayText&quot;:&quot;&quot;,&quot;fileName&quot;:&quot;imageformattinghelper_wikitraccs.png&quot;,&quot;siteId&quot;:&quot;cef85835-105a-4fc2-8c71-c0e9af03a152&quot;,&quot;webId&quot;:&quot;7d0da7b6-ccec-4b11-adf3-e15fdff55c4d&quot;,&quot;listId&quot;:&quot;b88ac73b-c39c-45ec-8d65-3ed3e6f09ea8&quot;,&quot;uniqueId&quot;:&quot;9b4b1659-bb2a-436d-9f81-2442229a9f1d&quot;,&quot;imgWidth&quot;:1,&quot;imgHeight&quot;:1,&quot;alignment&quot;:&quot;Center&quot;,&quot;fixAspectRatio&quot;:true},&quot;dynamicDataPaths&quot;:{},&quot;dynamicDataValues&quot;:{},&quot;serverProcessedContent&quot;:{&quot;imageSources&quot;:{&quot;imageSource&quot;:&quot;$serverRelativeWebUrl/$folderName/imageformattinghelper_wikitraccs.png&quot;}}}">
            <div data-sp-componentid="d1d91016-032f-456d-98a4-721247c305e8"></div>
            <div data-sp-htmlproperties=""><img data-sp-prop-name="imageSource"
                    src="$serverRelativeWebUrl/$folderName/$imageFilename"></img>
            </div>
        </div>
    </div>
    <div data-sp-canvascontrol="" data-sp-canvasdataversion="1.0"
        data-sp-controldata="{&quot;editorType&quot;:&quot;CKEditor&quot;,&quot;controlType&quot;:4,&quot;id&quot;:&quot;fcdc347c-a460-4e7c-9065-bba95875a479&quot;,&quot;position&quot;:{&quot;controlIndex&quot;:5,&quot;zoneIndex&quot;:1,&quot;sectionIndex&quot;:1,&quot;sectionFactor&quot;:12,&quot;layoutIndex&quot;:1},&quot;emphasis&quot;:{&quot;zoneEmphasis&quot;:0},&quot;zoneGroupMetadata&quot;:null}">
        <div data-sp-rte="">
            <p>Text before</p>
            <div tabindex="0" data-cke-widget-wrapper="1" data-cke-filter="off"
                class="cke_widget_wrapper cke_widget_block cke_widget_inlineimage cke_widget_wrapper_webPartInRteInlineImage cke_widget_wrapper_webPartInRte cke_widget_wrapper_webPartInRteAlignLeft"
                data-cke-display-name="div" data-cke-widget-id="0" role="region"
                aria-label="Inline image in RTE. Use Alt + F11 to go to toolbar. Use Alt + P to open the property pane.">
                <div data-webpart-id="image"
                    class="webPartInRte webPartInRteInlineImage cke_widget_element webPartInRteAlignLeft"
                    data-cke-widget-data="%7B%22classes%22%3A%7B%22webPartInRteInlineImage%22%3A1%2C%22webPartInRteAlignLeft%22%3A1%2C%22webPartInRte%22%3A1%7D%7D"
                    data-cke-widget-upcasted="1" data-cke-widget-keep-attr="0" data-widget="inlineimage"
                    data-instance-id="a94e6edf-8fe7-4c60-8c37-97b36d50708c" title=""></div>
            </div>
            <div tabindex="0" data-cke-widget-wrapper="1" data-cke-filter="off"
                class="cke_widget_wrapper cke_widget_block cke_widget_inlineimage cke_widget_wrapper_webPartInRteInlineImage cke_widget_wrapper_webPartInRte cke_widget_wrapper_webPartInRteAlignLeft"
                data-cke-display-name="div" data-cke-widget-id="0" role="region"
                aria-label="Inline image in RTE. Use Alt + F11 to go to toolbar. Use Alt + P to open the property pane.">
                <div data-webpart-id="image"
                    class="webPartInRte webPartInRteInlineImage cke_widget_element webPartInRteAlignLeft"
                    data-cke-widget-data="%7B%22classes%22%3A%7B%22webPartInRteInlineImage%22%3A1%2C%22webPartInRteAlignLeft%22%3A1%2C%22webPartInRte%22%3A1%7D%7D"
                    data-cke-widget-upcasted="1" data-cke-widget-keep-attr="0" data-widget="inlineimage"
                    data-instance-id="7c7f3c3c-f518-4d4c-b618-02c48eb5fccc" title=""></div>
            </div>
            <div tabindex="0" data-cke-widget-wrapper="1" data-cke-filter="off"
                class="cke_widget_wrapper cke_widget_block cke_widget_inlineimage cke_widget_wrapper_webPartInRteInlineImage cke_widget_wrapper_webPartInRte cke_widget_wrapper_webPartInRteAlignRight"
                data-cke-display-name="div" data-cke-widget-id="0" role="region"
                aria-label="Inline image in RTE. Use Alt + F11 to go to toolbar. Use Alt + P to open the property pane.">
                <div data-webpart-id="image"
                    class="webPartInRte webPartInRteInlineImage cke_widget_element webPartInRteAlignRight"
                    data-cke-widget-data="%7B%22classes%22%3A%7B%22webPartInRteInlineImage%22%3A1%2C%22webPartInRteAlignRight%22%3A1%2C%22webPartInRte%22%3A1%7D%7D"
                    data-cke-widget-upcasted="1" data-cke-widget-keep-attr="0" data-widget="inlineimage"
                    data-instance-id="292dfedc-37ca-4613-8c24-5c83092de8fd" title=""></div>
            </div>
            <div tabindex="0" data-cke-widget-wrapper="1" data-cke-filter="off"
                class="cke_widget_wrapper cke_widget_block cke_widget_inlineimage cke_widget_wrapper_webPartInRteInlineImage cke_widget_wrapper_webPartInRte cke_widget_wrapper_webPartInRteAlignCenter"
                data-cke-display-name="div" data-cke-widget-id="0" role="region"
                aria-label="Inline image in RTE. Use Alt + F11 to go to toolbar. Use Alt + P to open the property pane.">
                <div data-webpart-id="image"
                    class="webPartInRte webPartInRteInlineImage cke_widget_element webPartInRteAlignCenter"
                    data-cke-widget-data="%7B%22classes%22%3A%7B%22webPartInRteInlineImage%22%3A1%2C%22webPartInRteAlignCenter%22%3A1%2C%22webPartInRte%22%3A1%7D%7D"
                    data-cke-widget-upcasted="1" data-cke-widget-keep-attr="0" data-widget="inlineimage"
                    data-instance-id="2a41b9af-b37f-4650-80ab-58821073607e" title=""></div>
            </div>
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