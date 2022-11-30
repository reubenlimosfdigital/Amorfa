import { api, LightningElement, track, wire } from 'lwc';
import getCartItems from '@salesforce/apex/OSF_B2BShippingUnitUtilization.getCartItems';
import communityId from '@salesforce/community/Id';
import lightning__commerce_cartChanged from "@salesforce/messageChannel/lightning__commerce_cartChanged";
import { APPLICATION_SCOPE, MessageContext, publish, subscribe, unsubscribe } from "lightning/messageService";

export default class osfShippingUnitUtilization extends LightningElement {

    @track
    fullPalletCount;
    @track
    lastPalletUtilisationPercent;
    @api
    recordId;
    @track
    isLoading;
    @api
    shippingUnitLabel;
    @api
    componentSubtext;
    @api
    componentHeader;

    /**
     * The MessageContext to publish and/or subscribe
     */
    @wire(MessageContext)
    messageContext;
    subscription = null;

    connectedCallback() {
        //this.isLoading = true;
        this.fetchCartItems();
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                lightning__commerce_cartChanged,
                () => this.handleCartChanged(),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleCartChanged() {
        this.isLoading = true;
        this.fetchCartItems();
    }

    /**
    * This lifecycle hook fires when this component is destroyed in DOM.
    */
    disconnectedCallback() {
        unsubscribe(this.subscription);
    }

    get widthPercentage() {
        return `width:${this.lastShippingUnitUtilisationPercent}%`
    }

    fetchCartItems() {
        getCartItems({
            communityId: communityId,
            activeCartOrId: this.recordId,
        })
            .then((result) => {
                this.isLoading = false;
                console.log(result);
                this.fullShippingUnitCount = result.fullShippingUnitCount;
                this.lastShippingUnitUtilisationPercent = result.lastShippingUnitUtilisationPercent;
            })
            .catch((error) => {
                console.log(error);
            });
    }
}