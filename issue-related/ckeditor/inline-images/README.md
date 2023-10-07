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

### Expected behavior

The page should look like this in **view** mode (CKEditor **v4**):

![Page in view mode](https://github.com/WikiTransformationProject/library/blob/main/issue-related/ckeditor/inline-images/images/page-view-mode.png)

And like this in **edit** mode (CKEditor **v4**):

![Page in edit mode](https://github.com/WikiTransformationProject/library/blob/main/issue-related/ckeditor/inline-images/images/page-edit-mode.png)

### Unexpected behavior / Regression

This video shows the auto-upgrade in action that SharePoint does when editing a page, inlcuding mispositioned and even vanishing images:

https://github.com/WikiTransformationProject/library/assets/3469970/6a38d672-94be-48c9-a912-d946bd6e436f


I used the browser's developer tools to slow down the internet connection, which allows us to watch everything in slow motion.

What can be seen in above video:

1. the page enters edit mode and the images can be seen next to each other for a brief moment
2. then all web part content vanishes; the auto-upgrade happens
3. the web part content reappears; the images are placed on top of each other
4. bonus: all images are gone! (this was a first when recording this video)

This is a regression. Microsoft, please restore the behavior as it was with CKEditor v4. The images need to be shown next to each other.
