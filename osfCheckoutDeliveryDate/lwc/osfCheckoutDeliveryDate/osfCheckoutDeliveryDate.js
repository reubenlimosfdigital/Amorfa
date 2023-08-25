import { LightningElement, api, wire } from 'lwc';
import { CartSummaryAdapter } from 'commerce/cartApi';
import getCartDeliveryGroup from '@salesforce/apex/OSF_CheckoutDeliveryDateController.getCartDeliveryGroup';
import updateCartDeliveryGroup from '@salesforce/apex/OSF_CheckoutDeliveryDateController.updateCartDeliveryGroup';

const TODAY = new Date();

export default class OsfCheckoutDeliveryDate extends LightningElement {
    @api excludeWeekends = false;
    @api datePickerLabel;
    @api showTimePicker;
    @api isMandaroty;
    @api timePickerLabel;

    requestedDate;
    requestedTime;
    cartDetails;
    error;
    disabledDates = [];
    showDatepickerLoader = false;
    cartDeliveryGroupRecord;
    showDatepickerError = false;
    showTimepickerError = false;

    @api
    checkoutMode = 1;

    @api
    get checkValidity() {
        this.showDatepickerError = Boolean(this.error) || !this.requestedDate;
        if (!this.requestedDate) this.showDatepickerError = true;
        // if (!this.requestedTime) this.showTimepickerError = true;
        return !this.showDatepickerError;
    }

    @api
    async reportValidity() {
        console.log('reportValidity -> ', this.checkValidity);
        if (!this.checkValidity) {
            this.error = 'Requested Delivery Date should be future dates.';
            throw new Error(this.error);
        }

        return this.checkValidity();
    }

    @api
    async placeOrder() {
        this.reportValidity();
    }

    /**
     * Retrieves the cart details from the CartSummaryAdapter
     * @param {Object} CartSummaryAdapter - The CartSummaryAdapter wire adapter
     * @param {Object} error - The error object if an error occurs
     * @param {Object} data - The data object returned from the wire adapter
     */
    @wire(CartSummaryAdapter)
    CartSummaryAdapterFunc({ error, data }) {
        if (data) {
            this.cartDetails = { ...data };
            this.retrieveCartDeliveryGroup(this.cartDetails.cartId);
        } else if (error) {
            console.error(error);
        }
    }

    /**
     * Retrieves the cart delivery group record from the server
     * @param {string} cartId - the ID of the cart
     */
    async retrieveCartDeliveryGroup(cartId) {
        if (!cartId) return;
        getCartDeliveryGroup({ cartId: cartId })
            .then((result) => {
                console.log('@@@CHAN result -> ' + result);
                this.cartDeliveryGroupRecord = JSON.parse(result);
                console.log(this.cartDeliveryGroupRecord.DesiredDeliveryDate);
                this.requestedDate = this.cartDeliveryGroupRecord.DesiredDeliveryDate
                    ? new Date(this.cartDeliveryGroupRecord.DesiredDeliveryDate)
                    : '';
                this.requestedTime = this.cartDeliveryGroupRecord.DesiredDeliveryTime;
            })
            .catch((error) => console.error('ERROR in retrieveCartDeliveryGroup()', error));
    }

    /**
     * Sets up weekends for the calendar
     */
    async connectedCallback() {
        this.setupWeekends();
    }

    /**
     * Updates the cart delivery group with the requested date
     * @param {Object} cartDeliveryGroupRecord - the record of the cart delivery group
     * @param {Date} requestedDate - the requested date to be set
     * @returns {Promise} - a promise that resolves when the update is successful
     */
    async updateCartDeliveryGroup() {
        const formattedDate = `${this.requestedDate.getFullYear()}-${
            this.requestedDate.getMonth() + 1
        }-${this.requestedDate.getDate()}`;

        const formattedTime = this.requestedTime ? this.requestedTime : '9:00 AM';
        this.showDatepickerLoader = true;
        updateCartDeliveryGroup({
            recordId: this.cartDeliveryGroupRecord.Id,
            requestedDeliveryDate: formattedDate,
            requestedDeliveryTime: formattedTime,
        })
            .then(() => {
                console.log('updateCartDeliveryGroup: success');
                this.showDatepickerLoader = false;
            })
            .catch((error) => {
                console.error('Error: ', { error });
            });
    }

    /**
     * Sets the default date to TODAY + 1 and makes sure that the defaultDate doesn't fall on any holidays or weekends
     * @returns {Date} the default date
     */
    defaultDate() {
        // set the default date to TODAY + 1 as per user story
        let defaultDate = new Date(TODAY.getFullYear(), TODAY.getMonth(), TODAY.getDate() + 1);

        if (this.disabledDates.length) {
            const sortedDisabledDates = this.sortDates(this.disabledDates);

            // make sure that the defaultDate doesn't fall on any holidays or weekends
            defaultDate = this.offsetIncorrectDate(sortedDisabledDates, defaultDate);
        }

        return defaultDate;
    }

    /**
     * Offset incorrect date if it is already present in the sortedDates array
     * @param {Array} sortedDates - array of sorted dates
     * @param {Date} defaultDate - default date
     * @returns {Date} - the offset date
     */
    offsetIncorrectDate(sortedDates, defaultDate) {
        sortedDates.every((date) => {
            if (date.setHours(0, 0, 0, 0) === defaultDate.setHours(0, 0, 0, 0)) {
                defaultDate.setDate(defaultDate.getDate() + 1);
            }
            if (date > defaultDate) return false;
            return true;
        });
        return defaultDate;
    }

    /**
     * Get all weekend dates in a given month
     * @param {number} month - the month to get weekend dates for
     * @param {number} year - the year to get weekend dates for
     * @returns {Array} - an array of Date objects for all weekends in the given month
     */
    getWeekendDates(month, year) {
        const daysInMonth = new Date(year, month, 0).getDate();
        let weekends = [];
        for (let i = 1; i <= daysInMonth; i++) {
            let newDate = new Date(year, month, i);
            if (newDate > TODAY && (newDate.getDay() === 0 || newDate.getDay() === 6)) {
                weekends.push(newDate);
            }
        }

        return weekends;
    }

    /**
     * Sorts the given array of dates
     * @param {Array} datesArr - array of dates
     * @returns {Array} - sorted array of dates
     */
    sortDates(datesArr) {
        datesArr.sort(function (a, b) {
            return a - b;
        });
        return datesArr;
    }

    /**
     * Sets up the weekends to be excluded from the calendar
     * @returns {void}
     */
    setupWeekends() {
        // if weekends are disabled get at least the weekends till next month
        if (this.excludeWeekends) {
            const currMonth = TODAY.getMonth();
            const nextMonth = currMonth === 11 ? 0 : currMonth + 1;
            const currYear = TODAY.getFullYear();

            this.disabledDates = [
                ...this.disabledDates,
                ...this.getWeekendDates(currMonth, currYear),
                ...this.getWeekendDates(nextMonth, currMonth === 11 ? currYear + 1 : currYear), // get till next month
            ];
        }
    }

    /**
     * Handles the date selection event and updates the cart delivery group
     * @param {Event} event - the date selection event
     */
    handleDateSelect(event) {
        this.requestedDate = event.detail;
        this.updateCartDeliveryGroup();
    }

    handleTimeSelect(event) {
        this.requestedTime = event.detail;
        this.updateCartDeliveryGroup();
        console.log('@@@CHAN time -> ', event.detail);
    }
}