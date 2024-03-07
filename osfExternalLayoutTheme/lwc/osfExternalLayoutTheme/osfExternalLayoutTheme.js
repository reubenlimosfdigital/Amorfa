import { LightningElement } from 'lwc';
import OSF_ASSETS from '@salesforce/resourceUrl/osfCommerceAssets';

export default class OsfExternalLayoutTheme extends LightningElement {
    get backgroundStyle() {
        return `display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                background-image: url(${OSF_ASSETS}/osfCommerceAssets/images/LFA-Background-BLACK.jpg);
                background-size: cover;
                background-repeat: no-repeat;
                background-attachment: fixed;
                background-position: center;`;
    }
}