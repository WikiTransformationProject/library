# Repro

Repro for [Modern pages with text web parts upgraded from CKEditor v4 to v5 lose image positioning](https://techcommunity.microsoft.com/t5/sharepoint-developer/modern-pages-with-text-web-parts-upgraded-from-ckeditor-v4-to-v5/m-p/3927312).

## What does it do?

This script creates a modern SharePoint page with a text web part. This text web part uses CKEditor v4 as indicated by the contentVersion in the HTML below.

The text web part has 4 inline images, which reference 4 image web parts. Those image web parts all point to the same image file.

The image file will be uploaded to the SiteAssets library.

The resulting page should display three images in one row, next to each other. Three adjacent images. This is possible by left aligning all images, except the last one, which is right aligned.

And there is one trick: the fourth image is centered, which prevents the text from floating between the images. The centered image, which has a size of 1 pixel, acts as a "floatbreaker".