# Repro

Repro for [Modern pages with text web parts upgraded from CKEditor v4 to v5 lose image positioning](https://techcommunity.microsoft.com/t5/sharepoint-developer/modern-pages-with-text-web-parts-upgraded-from-ckeditor-v4-to-v5/m-p/3927312).

## What does it do?

This script creates a modern SharePoint page with a text web part. This text web part uses CKEditor v4 (`contentVersion` is set to `4`).

The text web part shows 4 inline images, which reference 4 image web parts. Those image web parts all point to the same image file.

The image file will be uploaded to the SiteAssets library.

The resulting page should display three images in one row, next to each other. Three adjacent images. This is possible by left aligning all images, except the last one, which is right aligned.

And there is one trick: the fourth image is centered, which prevents the text from floating between the images. The centered image, which has a size of 1 pixel, acts as a "floatbreaker".

## How to use?

* clone the repo
* set the "current directory" to the script's path (so that the image can be found)
* in the script, set the URL of a SharePoint site to test with
* run the script
* authenticate with SharePoint

The script should create a modern page with images.

## Visuals

### Expected behavior with CKEditor v4

The page should look like this in **view** mode (CKEditor **v4**):

![Page in view mode](https://github.com/WikiTransformationProject/library/blob/main/issue-related/ckeditor/inline-images/images/page-view-mode.png)

And like this in **edit** mode (CKEditor **v4**):

![Page in edit mode](https://github.com/WikiTransformationProject/library/blob/main/issue-related/ckeditor/inline-images/images/page-edit-mode.png)

### Unexpected behavior / Regression with CKEditor v5

This video shows the text web part auto-upgrade in action that SharePoint does when editing a page, including mispositioned and even vanishing images:

https://github.com/WikiTransformationProject/library/assets/3469970/6a38d672-94be-48c9-a912-d946bd6e436f

*Note: I used the browser's developer tools to slow down the internet connection, which allows us to watch everything in slow motion.*

What can be seen in above video:

1. the page enters edit mode and the three inline images can be seen next to each other for a brief moment
2. then all web part content vanishes; the auto-upgrade happens where SharePoint converts the content from CKEditor v4 to CKEditor v5
3. the web part content reappears; the images are placed on top of each other (NOT GOOD)
4. bonus: all images are gone! (this was a first when recording this video) (NOT GOOD)

Editing this page worked perfectly fine for at least the last 12 months. Images stayed in place, no problems.

## How to detect the CKEditor version the text web part uses?

One of the ways to see which CKEditor version a SharePoint page uses can be seen in the browser's developer tools.

Looking at the CSS styles you'll see the `.rte--ck5` selector, both in view and edit mode of a page. This means the page uses CKEditor v5:

![Upgraded page styles](https://github.com/WikiTransformationProject/library/blob/main/issue-related/ckeditor/inline-images/images/ckeditor-v5-style.png)

As of writing this there is no information if this feature is already GA. So there will be pages out there that behave differently when being edited. For pages still using CKEditor v4 there wont be the `.rte--ck5` CSS selector.

## Plea

This is a regression for modern SharePoint pages using inline images. Microsoft, please restore the behavior as it was before upgrading (perfectly fine) old pages. The inline images need to be shown next to each other.

I opened a support request with Microsoft, the ID is 2310071420000151.
