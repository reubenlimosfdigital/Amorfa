import { LightningElement, api, track } from 'lwc';

const MONTHS = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
];
const MONTHS_SHORTHAND = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const DAYS_LONGHAND = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

export default class OsfDatepicker extends LightningElement {
    @track dates = [];
    @track currDate = new Date();
    @api showTimepickerField;
    @api allowedDates = [];
    @api excludeWeekends = false;
    @api isMandaroty;
    @api showTimepickerError = false;
    @api showDatepickerError = false;
    @api showDatepickerLoader = false;

    today = new Date();
    _label = 'Date';
    _timepickerLabel = 'Time';
    _selectedDate;
    _selectedTime;
    _disabledDates = [];
    _handler;
    formattedSelectedDate = '';
    formattedSelectedTime = '';
    isPrevButtonDisabled = false;
    prevStyle;
    isDatepickerVisibile = false;
    timeArray;
    isTimepickerOpen = false;

    /**
     * Getter for the timepicker label
     * @returns {string} the timepicker label
     */
    @api
    get timepickerLabel() {
        return this._timepickerLabel;
    }

    /**
     * Setter for the timepicker label
     * @param {string} value - the timepicker label
     */
    set timepickerLabel(value) {
        console.log('@@@CHAN -> ', value);
        this._timepickerLabel = value;
    }

    /**
     * Getter for the label property
     * @returns {string} label
     */
    @api
    get label() {
        return this._label;
    }

    /**
     * Setter for the label attribute
     * @param {string} value - the value of the label
     */
    set label(value) {
        this._label = value;
    }

    /**
     * Getter for the selected date
     * @returns {Date} the selected date
     */
    @api
    get selectedDate() {
        return this._selectedDate;
    }

    /**
     * Sets the selected date
     * @param {Date} value - the selected date
     */
    set selectedDate(value) {
        this._selectedDate = value;
        if (!value) return;
        let year = value.getFullYear();
        let month = value.getMonth();
        let date = value.getDate();
        let day = value.getDay();
        this.formattedSelectedDate = `${DAYS_LONGHAND[day]}, ${date} ${MONTHS_SHORTHAND[month]} ${year}`;
        this.currDate = value;
        this.resfreshDate();
    }

    @api
    get selectedTime() {
        return this._selectedTime;
    }

    set selectedTime(value) {
        this._selectedTime = value;
        if (!value) return;
        this.formattedSelectedTime = value;
    }

    /**
     * Getter for the disabledDates property
     * @returns {Array} - array of disabled dates
     */
    @api
    get disabledDates() {
        return this._disabledDates;
    }

    /**
     * Set the disabled dates for the datepicker
     * @param {Array} value - An array of dates to be disabled
     */
    set disabledDates(value) {
        this._disabledDates = value;
    }

    get timepickerClass() {
        let classes = 'slds-form-element';
        if (this.showTimepickerError) {
            classes += ' slds-has-error';
        }
        return classes;
    }

    get datepickerClass() {
        let classes = 'slds-form-element__control';
        if (this.showDatepickerError) {
            classes += ' slds-has-error';
        }
        return classes;
    }

    /**
     * Returns the year of the current date
     * @returns {number} - the year of the current date
     */
    get year() {
        return this.currDate.getFullYear();
    }

    /**
     * Get the month of the current date
     * @returns {string} the month of the current date
     */
    get month() {
        return MONTHS[this.currDate.getMonth()];
    }

    /**
     * Returns a list of years from the current year to 15 years in the future
     * @returns {Array} - an array of objects containing the year and a boolean indicating if it is the current year
     */
    get yearList() {
        let startYear = this.today.getFullYear();
        return Array(15)
            .fill(0)
            .map(() => {
                let year = startYear;
                startYear++;
                return { value: year, selected: this.currDate.getFullYear() === year };
            });
    }

    /**
     * Toggles the visibility of the datepicker
     */
    showDatepicker(event) {
        this.isDatepickerVisibile = !this.isDatepickerVisibile;
        event.stopPropagation();
        return false;
    }

    /**
     * Toggles the visibility of the timepicker
     */
    showTimepicker(event) {
        this.isTimepickerOpen = !this.isTimepickerOpen;
        event.stopPropagation();
        return false;
    }

    /**
     * Sets the previous button to be disabled if the current context is less than or equal to the today context
     */
    setPreviousButton() {
        let currContext = new Date(this.currDate.getFullYear(), this.currDate.getMonth(), 1);
        let todayContext = new Date(this.today.getFullYear(), this.today.getMonth(), 1);
        this.isPrevButtonDisabled = currContext <= todayContext;
    }

    async connectedCallback() {
        this.resfreshDate();
        this.generateTimeArray();
        // Add event listener to the document
        // document.addEventListener('click', this.handleDocumentClick.bind(this));
        document.addEventListener('click', (this._handler = this.handleDocumentClick.bind(this)));
    }

    disconnectedCallback() {
        // Remove event listener when component is removed from the DOM
        document.removeEventListener('click', this._handler);
    }

    ignore(event) {
        event.stopPropagation();
        return false;
    }

    handleDocumentClick() {
        this.isDatepickerVisibile = false;
        this.isTimepickerOpen = false;
    }

    /**
     * Handles the selection of a year in the datepicker
     * @param {Event} event - the event object
     */
    handleYearSelect(event) {
        this.currDate = new Date(event.target.value, this.currDate.getMonth(), this.currDate.getDate());
        this.resfreshDate();
    }

    /**
     * Sets the current date to the previous month
     */
    previousMonth() {
        const currMonth = this.currDate.getMonth() === 0 ? 11 : this.currDate.getMonth() - 1;
        const currYear = this.currDate.getMonth() === 0 ? this.currDate.getFullYear() - 1 : this.currDate.getFullYear();
        this.currDate = new Date(currYear, currMonth, this.currDate.getDate());
        this.resfreshDate();
    }

    /**
     * Increments the current month by one
     */
    nextMonth() {
        const currMonth = this.currDate.getMonth() === 11 ? 0 : this.currDate.getMonth() + 1;
        const currYear =
            this.currDate.getMonth() === 11 ? this.currDate.getFullYear() + 1 : this.currDate.getFullYear();
        this.currDate = new Date(currYear, currMonth, this.currDate.getDate());
        this.resfreshDate();
    }

    /**
     * Sets the current date to the current day
     */
    goToday() {
        this.currDate = this.today;
        this.resfreshDate();
    }

    /**
     * Updates the year option in the date picker
     */
    updateYear() {
        const yearElem = this.template.querySelector('.year-options');
        if (yearElem) yearElem.value = this.currDate.getFullYear();
    }

    /**
     * Sets the selected date in the datepicker
     * @param {Event} event - the click event from the datepicker
     */
    setSelected(event) {
        const selectedDate = new Date(event.target.dataset.dateObj);

        const isDisabledViaClass = event.target.classList.contains('disabled');
        if (isDisabledViaClass) return;
        if (this.isDateDisabled(selectedDate)) return; // weekend should not be selected

        const selectedElem = this.template.querySelector('.selected');
        if (selectedElem) {
            selectedElem.classList = 'date';
        }

        this._selectedDate = selectedDate;
        event.target.className = 'selected';

        this.formattedSelectedDate = event.target.dataset.date;

        this.template.querySelector('.input-date').value = selectedDate;

        this.dispatchEvent(new CustomEvent('dateselect', { detail: selectedDate }));
        this.isDatepickerVisibile = false;
        this.currDate = this._selectedDate;
        this.resfreshDate();
    }

    /**
     * Checks if the selected date is disabled
     * @param {Date} selectedDate - the selected date
     * @returns {boolean} - true if the selected date is disabled, false otherwise
     */
    isDateDisabled(selectedDate) {
        let isDisabled = false;
        if (this._disabledDates.length) {
            isDisabled = Boolean(
                this._disabledDates.find((disabledDay) => {
                    return disabledDay.setHours(0, 0, 0, 0) === selectedDate.setHours(0, 0, 0, 0);
                })
            );
        }

        const disableWeekends = this.excludeWeekends && (selectedDate.getDay() === 0 || selectedDate.getDay() === 6);

        return disableWeekends || selectedDate <= this.today || isDisabled;
    }

    /**
     * Refreshes the current date and updates the calendar
     */
    @api
    resfreshDate() {
        this.updateYear();
        console.log('resfresh');
        this.setPreviousButton();
        this.dates = [];

        let currYear = this.currDate.getFullYear();
        let currMonth = this.currDate.getMonth();

        let firstDayOfMonth = new Date(currYear, currMonth, 1).getDay();
        let lastDateOfMonth = new Date(currYear, currMonth + 1, 0).getDate();
        let lastDayOfMonth = new Date(currYear, currMonth, lastDateOfMonth).getDay();
        let lastDateOfLastMonth = new Date(currYear, currMonth, 0).getDate();

        // previous month's dates
        for (let i = firstDayOfMonth; i > 0; i--) {
            let className = 'date previous-month';

            let day = new Date(currYear, currMonth - 1, lastDateOfLastMonth + 1 - i);
            let dayDate = day.getDate();
            let dayOfWeek = day.getDay();

            className += this.checkDisabledClass(dayOfWeek, day);
            this.dates.push({
                className,
                formatted: `${MONTHS_SHORTHAND[currMonth - 1]} ${dayDate}, ${currYear}`,
                text: dayDate,
                dateObj: day,
            });
        }

        // current month's dates
        for (let i = 1; i <= lastDateOfMonth; i++) {
            let className = 'date';

            let day = new Date(currYear, currMonth, i);
            let dayOfWeek = day.getDay();

            className += this.checkDisabledClass(dayOfWeek, day);
            if (day.setHours(0, 0, 0, 0) === this.today.setHours(0, 0, 0, 0)) {
                className += ' today';
            }

            if (this._selectedDate && this._selectedDate.setHours(0, 0, 0, 0) === day.setHours(0, 0, 0, 0)) {
                className += ' selected';
            }

            this.dates.push({
                className,
                formatted: `${MONTHS_SHORTHAND[currMonth]} ${i}, ${currYear}`,
                text: i,
                dateObj: day,
            });
        }

        // next month's dates
        for (let i = 1; i <= 6 - lastDayOfMonth; i++) {
            let className = 'date next-month';

            let day = new Date(currYear, currMonth + 1, i);
            let dayOfWeek = day.getDay();

            className += this.checkDisabledClass(dayOfWeek, day);
            this.dates.push({
                className,
                formatted: `${MONTHS_SHORTHAND[currMonth + 1]} ${i}, ${currYear}`,
                text: i,
                dateObj: day,
            });
        }
    }

    /**
     * Checks if the day is disabled
     * @param {number} dayOfWeek - day of the week (0-6)
     * @param {Date} day - the day to check
     * @returns {string} - the disabled class if the day is disabled
     */
    checkDisabledClass(dayOfWeek, day) {
        let isDisabled = false;
        if (this._disabledDates.length) {
            isDisabled = Boolean(
                this._disabledDates.find((disabledDay) => {
                    return disabledDay.setHours(0, 0, 0, 0) === day.setHours(0, 0, 0, 0);
                })
            );
        }

        const disableWeekends = this.excludeWeekends && (dayOfWeek === 0 || dayOfWeek === 6);

        return disableWeekends || day <= this.today || isDisabled ? ' disabled' : '';
    }

    /**
     * Generates an array of times with 30 minute intervals
     * @param {number} intervals - Interval in minutes
     * @param {number} startTime - Start time in hours
     * @param {number} endTime - End time in hours
     */
    generateTimeArray() {
        const times = [];
        const intervals = 30; // Interval in minutes
        const startTime = 9; // Start time in hours
        const endTime = 17; // End time in hours

        for (let i = startTime; i <= endTime; i += intervals / 60) {
            const hours = Math.floor(i);
            const minutes = (i % 1) * 60;
            const time = this.formatTime(hours, minutes);
            times.push(time);
        }

        this.timeArray = times;
    }

    /**
     * Formats the given hours and minutes into a 12-hour clock format
     * @param {number} hours - the hours to format
     * @param {number} minutes - the minutes to format
     * @returns {string} - the formatted time string
     */
    formatTime(hours, minutes) {
        const meridiem = hours >= 12 ? 'PM' : 'AM';
        const formattedHours = hours % 12 || 12;
        const formattedMinutes = minutes.toString().padStart(2, '0');
        return `${formattedHours}:${formattedMinutes} ${meridiem}`;
    }

    /**
     * Handles time selection from the timepicker
     * @param {Event} event - The event object
     */
    handleTimeSelection(event) {
        this.isTimepickerOpen = false;
        console.log('evt', event.target.querySelector('span'));
        this.formattedSelectedTime = event.target.querySelector('span').title;
        this.dispatchEvent(new CustomEvent('timeselect', { detail: this.formattedSelectedTime }));
        console.log('handleTimeSelection', event.target.querySelector('span').title);
    }
}