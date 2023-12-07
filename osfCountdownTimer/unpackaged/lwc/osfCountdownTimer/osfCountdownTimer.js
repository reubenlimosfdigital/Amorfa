import { LightningElement, api } from 'lwc';

export default class OsfCountdownTimer extends LightningElement {

    @api targetDate;
    @api targetTime;
    @api timezone;

    @api recurringDaily;
    @api customTextColour;
    @api customBackgroundColour;
    @api showDays;
    @api showHours;
    @api showMinutes;
    @api showSeconds;

    @api textSize;
    @api numberSize;
    @api textAlignment;
    @api flipCountdown;

    _showCountdown;
    timeIntervalInstance;
    totalDifferenceInMilliseconds = 0;
    formattedTargetDateTime;
    days;
    hours;
    minutes;
    seconds;
    isInitialLoad = true;
    errorMessage = '';

    datePattern = /^(20[0-9]{2})-(0[1-9]|1[0-2])-([0-2][0-9]|3[0-1])$/;
    timePattern = /^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/;
    
    sizeMappings = {
        'Heading 1' : 'dxp-text-heading-xlarge', 
        'Heading 2': 'dxp-text-heading-large', 
        'Heading 3': 'dxp-text-heading-medium', 
        'Heading 4' : 'dxp-text-heading-small', 
        'Paragraph 1' : 'dxp-text-body', 
        'Paragraph 2' : 'dxp-text-body-small'
    };

    textColourMappings = {
        'Paragraph 2': '--dxp-s-body-small-text-color',
        'Paragraph 1': '--dxp-s-body-text-color',
        'Heading 4': '--dxp-s-text-heading-small-color',
        'Heading 3': '--dxp-s-text-heading-medium-color',
        'Heading 2': '--dxp-s-text-heading-large-color',
        'Heading 1': '--dxp-s-text-heading-extra-large-color'
    };

    set showCountdown(value) {
        this._showCountdown = value;
    }

    get showCountdown() {
        return this.totalDifferenceInMilliseconds > 0;
    }

    renderedCallback() {
        this.updateText();
    }

    connectedCallback() {
        
        let textColourForStyling = '--text-colour: '+this.customTextColour;
        let backgroundColourForStyling = '--background-colour: '+this.customBackgroundColour;
        let textAlignmentForStyling = '--text-alignment: '+this.textAlignment;
        this.stylingForCountdownTimer = textColourForStyling+';'+backgroundColourForStyling+';'+textAlignmentForStyling;

        // Validate targetDate and targetTime format
        if (!this.targetDate.match(this.datePattern)) {
            this.errorMessage = 'Invalid targetDate format. Please use the format: YYYY-MM-DD';
        } 
        if (!this.targetTime.match(this.timePattern)) {
            this.errorMessage = 'Invalid targetTime format. Please use the format: HH:MM:SS';
        }

        this.start();
    }

    /**
    * Updates the HTML classes for text size and number size
    */
    updateText = () => {
        // Update the html classes for text size and number size
        const textElements = this.template.querySelectorAll('.text');
        const numberElements = this.template.querySelectorAll('.number');

        // remove classes if not the initial load
        if (!this.isInitialLoad) {
            this.removeClasses(textElements);
            this.removeClasses(numberElements);
        } else {
            this.isInitialLoad = false;
        }

        this.addClassesAndProperties(textElements, this.textSize);
        this.addClassesAndProperties(numberElements, this.numberSize);
    }

    removeClasses = (elements) => {
        elements.forEach((element) => {
            Object.values(this.sizeMappings).forEach((className) => {
                element.classList.remove(className);
            });
        });
    }

    addClassesAndProperties = (elements, size) => {
        elements.forEach((element) => {
            const sizeClass = this.sizeMappings[size];
            const textColourVariable = this.textColourMappings[size];
            element.classList.add(sizeClass);
            element.style.setProperty(textColourVariable, 'var(--text-colour)');
        });
    }

    start = () => {
        var parentThis = this;
        let currentDateTime = new Date();
        this.formattedTargetDateTime = new Date(this.targetDate + ' ' + this.targetTime);

        // Convert the target time to the provided timezone or the current user's timezone as a default
        const targetDateTime = this.convertToTargetTimezone(this.formattedTargetDateTime, this.timezone, currentDateTime);

        // Calculate the time difference
        this.totalDifferenceInMilliseconds = targetDateTime - currentDateTime;

        if (this.showCountdown) {
            // Update the count down every 100 milliseconds
            this.timeIntervalInstance = this.startCountdown(parentThis);
        } else if(parentThis.recurringDaily){
            parentThis.handleRecurringDaily();
        }      
    }

    startCountdown = (parentThis) => {
        // eslint-disable-next-line
        return setInterval(() => {
            // Time calculations for days, hours, minutes, seconds
            parentThis.days = Math.floor(parentThis.totalDifferenceInMilliseconds / (1000 * 60 * 60 * 24));
            parentThis.hours = Math.floor(parentThis.totalDifferenceInMilliseconds / (1000 * 60 * 60)) % 24;
            parentThis.minutes = Math.floor(parentThis.totalDifferenceInMilliseconds / (1000 * 60)) % 60;
            parentThis.seconds = Math.floor(parentThis.totalDifferenceInMilliseconds / 1000) % 60;
    
            // Subtract 100 milliseconds on total difference
            parentThis.totalDifferenceInMilliseconds -= 100;
    
            // clear interval if the countdown is done
            if (parentThis.totalDifferenceInMilliseconds <= 0) {
                clearInterval(parentThis.timeIntervalInstance);
            }
        }, 100);
    }

    convertToTargetTimezone = (formattedTargetDateTime, timezone, currentDateTime) => {
        const targetDateTime = new Date(formattedTargetDateTime);
        const targetTimezoneOffset = this.getTimezoneOffsetFromGMT(timezone);
        const localTimezoneOffset = currentDateTime.getTimezoneOffset();
        const timezoneOffsetDifference = targetTimezoneOffset - localTimezoneOffset;
        targetDateTime.setMinutes(targetDateTime.getMinutes() + timezoneOffsetDifference);
        return targetDateTime;
    }
    

    //converts the timezone into an offset from GMT
    //e.g. (GMT+10:00) Canberra, Melbourne, Sydney will return 600
    //e.g. (GMT-10:00) Hawaii will return -600
    getTimezoneOffsetFromGMT = (timezone) => {
        const gmtRegex = /\(GMT([+-])(\d{2}):(\d{2})\)/;
        const matches = gmtRegex.exec(timezone);
        if (matches) {
            const sign = matches[1] === '+' ? -1 : 1;
            const hours = parseInt(matches[2]);
            const minutes = parseInt(matches[3]);
            const offset = (hours * 60 + minutes) * sign;
            return offset;
        }
        return 0;
    }

    handleRecurringDaily = () => {
        //it will only ever enter this method if the original date/time has passed and recurr daily is ticked
        // Calculate the delay until the timer should start again
        let currentDateTime = new Date();
        let comingMidnight = new Date();
        comingMidnight.setHours(24, 0, 0, 0);
        let delay = comingMidnight - currentDateTime;
        
        // Convert the target time to the provided timezone
        const targetDateTime = this.convertToTargetTimezone(this.formattedTargetDateTime, this.timezone, currentDateTime);
        
        //set the new countdown timer to be equal to the original time of day that was specified
        let newCountdownTime = new Date();
        newCountdownTime.setHours(targetDateTime.getHours(), targetDateTime.getMinutes(), targetDateTime.getSeconds(), targetDateTime.getMilliseconds());
        
        let lastMidnight = new Date();
        lastMidnight.setHours(0, 0, 0, 0);
        if (currentDateTime >= lastMidnight && currentDateTime <= newCountdownTime) {
            this.totalDifferenceInMilliseconds = newCountdownTime - currentDateTime;
        }

        //if we updated the totalDifferenceInMilliseconds to be a positive number then display the timer
        if(this.totalDifferenceInMilliseconds >= 0){
            this.timeIntervalInstance = this.startCountdown(this);
        }
        //set the delayed timer for when the countdown should start again
        // eslint-disable-next-line
        setTimeout(() => {
            this.start();
        }, delay);
    }
}