/*------------------------------------------------------------
Author:        Priyanka Kumar
Company:       OSF Digital ANZ
Description:   Apex class to retrieve valid messages for the pop up message component     
Test Class:    OSF_CommunityPopUpMessageControllerTest
<Date>         <Authors Name>     <Brief Description of Change>
07-Oct-2022    Reuben Lim        Picklist preference excludion logic built for BATNZ.
------------------------------------------------------------*/
public with sharing class OSF_CommunityPopUpMessageController {

    // returns a list of customer messages for display on pop-up
    @AuraEnabled(cacheable=true)
    public static List<OSF_Customer_Message__c> getCustomerMessages() {
            return [SELECT OSF_Message_Title__c, OSF_Message_Body__c, OSF_Image_URL__c
                    FROM OSF_Customer_Message__c
                    WHERE OSF_Is_Active__c = TRUE
                    ORDER BY OSF_Message_Sequence__c ASC];
    }
}
