/**********************************************************************************************
* @Author:        Isaac Sedcole
* @Company:       OSF Digital ANZ
* @Description:   Gets all the picklist values for timezone and is used in the LWC osfCountdownTimer
* Test Class:     OSF_TimezonePicklist_Test
* <Date>          <Authors Name>     <Brief Description of Change>
* 06-Dec-2023     Isaac Sedcole      Initial Implementation
***********************************************************************************************/
global class OSF_TimezonePicklist extends VisualEditor.DynamicPickList {

    /**********************************************************************************************
    * @description  : Returns the default value for the timezone picklist
    * @return       : VisualEditor.DataRow - the default value for the timezone picklist
    ***********************************************************************************************/
    public override VisualEditor.DataRow getDefaultValue() {
        String userTimezone = UserInfo.getTimeZone().getID();
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(userTimezone, userTimezone);
        return defaultValue;
    }

    /**********************************************************************************************
    * @description  : Returns a list of picklist values for the User.TimeZoneSidKey field
    * @return       : VisualEditor.DynamicPickListRows - a list of picklist values
    ***********************************************************************************************/
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows picklistValues = new VisualEditor.DynamicPickListRows();
        List<Schema.PicklistEntry> timezonePicklistValues = User.TimeZoneSidKey.getDescribe().getPicklistValues();

        for (Schema.PicklistEntry picklistEntry : timezonePicklistValues) {
            String timezoneLabel = picklistEntry.getLabel();
            String timezoneValue = timezoneLabel;
            VisualEditor.DataRow value = new VisualEditor.DataRow(timezoneValue, timezoneLabel);
            picklistValues.addRow(value);
        }

        return picklistValues;
    }
}