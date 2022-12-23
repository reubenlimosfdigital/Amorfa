import { api, LightningElement } from 'lwc';

export default class OsfBanner extends LightningElement {

    @api bannerText;
    @api bannerTextColor;
    @api bannerBackgroundColor;
    @api allowUserToClose;
    @api hideBanner = false;
    @api bannerId;
    @api
    get getBackgroundAndFontColor() {
        return "background-color:" + this.bannerBackgroundColor + "; color:" + this.bannerTextColor + ";";
    }
    
    handleClick(event) {
        this.hideBanner = true;
        sessionStorage.setItem('hideBanner' + this.bannerId,'hide');
    }
    connectedCallback() {
        if (sessionStorage.getItem('hideBanner' + this.bannerId) != 'hide') {
            sessionStorage.setItem('hideBanner' + this.bannerId,'show');
        } else {
            this.hideBanner = true;
        }
    }
}