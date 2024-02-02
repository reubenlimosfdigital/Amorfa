This static resource contains the custom styling to enable the following:

1. A nice filter (compared to crappy SF filters)
2. Making the PLP list view look much nicer

To add it to the site, upload the static resource then do the following:
1. Go to Commerce LWR Experience Builder
2. Go to Settings > Advanced > Click on Edit Head Markup
3. Add the following CSS

<!-- Commerce Global Style -->
<link rel="stylesheet" href="{ basePath }/sfsites/c/resource/osfCommerceAssets/osfCommerceAssets/styles/OSF_CommerceGlobalStyle.min.css?{ versionKey }" />
