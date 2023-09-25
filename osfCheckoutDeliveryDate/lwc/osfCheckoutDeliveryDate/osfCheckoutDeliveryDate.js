import { LightningElement, api, wire } from 'lwc';
import { CartSummaryAdapter } from 'commerce/cartApi';
import getCartDeliveryGroup from '@salesforce/apex/OSF_CheckoutDeliveryDateController.getCartDeliveryGroup';
import updateCartDeliveryGroup from '@salesforce/apex/OSF_CheckoutDeliveryDateController.updateCartDeliveryGroup';

const TODAY = new Date();

export default class OsfCheckoutDeliveryDate extends LightningElement {
    requestedDate;
    requestedTime;
    cartDetails;
    error;
    disabledDates = [];
    showDatepickerLoader = false;
    cartDeliveryGroupRecord;
    showDatepickerError = false;
    showTimepickerError = false;

    @api excludeWeekends = false;
    @api datePickerLabel;
    @api showTimePicker;
    @api isMandatory;
    @api timePickerLabel;
    @api datepickerToolTipMessage;
    @api timepickerToolTipMessage;

    /**
     * @api checkoutMode The checkout mode (1 for single page checkout, 0 for multi-page checkout)
     */
    @api
    checkoutMode = 1;

    /**
     * Returns the validity of the requested date
     * @api
     * @returns {boolean} - true if valid, false if invalid
     */
    @api
    get checkValidity() {
        if (this.isMandatory) {
            this.showDatepickerError = Boolean(this.error) || !this.requestedDate;
            if (!this.requestedDate) this.showDatepickerError = true;
            return !this.showDatepickerError;
        }
        return true;
    }

    /**
     * Reports the validity of the component
     * @api
     * @returns {boolean} - true if the component is valid, false otherwise
     */
    @api
    reportValidity() {
        return this.checkValidity();
    }

    /**
     * Place an order
     */
    @api
    placeOrder() {
        this.reportValidity();
    }

    /**
     * Retrieves the cart details from the CartSummaryAdapter
     * @param {Object} CartSummaryAdapter - The CartSummaryAdapter wire adapter
     * @param {Object} error - The error object
     * @param {Object} data - The data object
     * @returns {Object} - The cart details
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
     * Retrieves the delivery group associated with the cart
     * @param {string} cartId - the ID of the cart
     * @returns {Object} - the delivery group associated with the cart
     */
    async retrieveCartDeliveryGroup(cartId) {
        if (!cartId) return;
        getCartDeliveryGroup({ cartId: cartId })
            .then((result) => {
                this.cartDeliveryGroupRecord = JSON.parse(result);
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

        const formattedTime = this.requestedTime && this.showTimePicker ? this.requestedTime : '00:00 AM';
        this.showDatepickerLoader = true;
        updateCartDeliveryGroup({
            recordId: this.cartDeliveryGroupRecord.Id,
            requestedDeliveryDate: formattedDate,
            requestedDeliveryTime: formattedTime,
            isTimePickerDisable: this.showTimePicker,
        })
            .then(() => {
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

    /**
     * Updates the requested delivery time and updates the cart delivery group
     * @param {Object} event - the event object
     */
    handleTimeSelect(event) {
        this.requestedTime = event.detail;
        this.updateCartDeliveryGroup();
    }
}
