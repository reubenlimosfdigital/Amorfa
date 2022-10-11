import { LightningElement,track,wire } from 'lwc';
import showMessages from '@salesforce/apex/OSF_CommunityPopUpMessageController.getCustomerMessages';

export default class osfCommunityPopUpMessage extends LightningElement {
    @track isShowModal = false;
    @track messages = [];
    @track currentMessage = [];
    @track showImage = false;
	@track error;
    indexVal = 0;

    connectedCallback(){
        var modalVal = sessionStorage.getItem("showModal");
        if(modalVal == 'hide'){
            this.isShowModal = false;
        }
    }

    @wire (showMessages)
	wiredMessages({data, error}){
		if (data) {
			this.error = undefined;
            this.messages = data;
            var modalVal = sessionStorage.getItem("showModal");
            if (modalVal != 'hide' && this.messages.length > 0) {
                this.isShowModal = true;
                this.currentMessage = data[0];
                if(this.currentMessage.OSF_Image_URL__c != null) {
                    this.showImage = true;
                }
                this.indexVal++;
            }
		} else {
			this.messages =undefined;
			this.error = error;
		}
	}

    showModalBox() {  
        this.isShowModal = true;
    }

    hideModalBox() {  
        this.isShowModal = false;
        if(this.indexVal < this.messages.length){
            this.currentMessage = this.messages[this.indexVal];
            if(this.currentMessage.OSF_Image_URL__c != null){
                this.showImage = true;
            }else{
                this.showImage = false;
            }
            this.indexVal++;
            this.isShowModal = true; 
        }
        if(this.indexVal == this.messages.length){
            sessionStorage.setItem('showModal', 'hide');
        }
    }
}