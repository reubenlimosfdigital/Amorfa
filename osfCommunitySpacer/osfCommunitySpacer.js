import { api, LightningElement } from 'lwc';

export default class OsfCommunitySpacer extends LightningElement {

    @api heightValue = 50;

    @api
    get generateStyleCSSValue() {
        return "height:" + this.heightValue + "px;"
    }

}