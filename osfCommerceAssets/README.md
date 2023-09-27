# Import Static Resource and Link Stylesheet in Experience Builder

This README provides step-by-step instructions on how to import a static resource and link a stylesheet in Experience Builder. Please follow the instructions below to complete the process.

## Import Static Resource

1. Go to Setup > Static Resource.
2. Click on "Create New Static Resource".
    - Name: osfCommerceAssets
    - Description: Global assets used in the commerce storefront
    - File: Choose the osfCommerceAssets.zip file located in this folder.
    - Cache Control: Public
3. Click "Save".

## Link the Stylesheet in Experience Builder

1. Go to Setup > Digital Experience > All Sites.
2. Select the LWR Site to which you want to add the stylesheet.
3. Click on the "Builder" link in the Action column.
4. In the Builder, navigate to "Setting" > "Advanced" and click the "Edit Head Markup" button.
5. Copy the following line and paste it in the Head Markup section:
    ```
    <link rel="stylesheet" href="{ basePath }/sfsites/c/resource/osfCommerceAssets/osfCommerceAssets/styles/OSF_CommerceGlobalStyle.css?{ versionKey }" />
    ```
    If you prefer to use the minified version, use the following line instead:
    ```
    <link rel="stylesheet" href="{ basePath }/sfsites/c/resource/osfCommerceAssets/osfCommerceAssets/styles/OSF_CommerceGlobalStyle.min.css?{ versionKey }" />
    ```
6. Click "Save".
7. Refresh the page to see the stylesheet in action.

Please follow these instructions carefully to ensure successful import of the static resource and linking of the stylesheet in Experience Builder. If you encounter any issues or have any questions, feel free to reach out for assistance.