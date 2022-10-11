@isTest
public with sharing class OSF_CommunityPopUpMessageControllerTest {

    @TestSetup
    private static void makeData(){
        
        List<OSF_Customer_Message__c> messageList = new List<OSF_Customer_Message__c>();

        // add a valid message
        messageList.add(new OSF_Customer_Message__c(OSF_Message_Title__c =' Test Title 1', OSF_Message_Body__c = 'Test Body 1',
                                                    OSF_Start_Date__c = date.today().addDays(-1), OSF_End_Date__c = date.today().addDays(1),
                                                    OSF_Message_Sequence__c = 1));
        
        // add a second valid message
        messageList.add(new OSF_Customer_Message__c(OSF_Message_Title__c =' Test Title 2', OSF_Message_Body__c = 'Test Body 2',
                                                    OSF_Start_Date__c = date.today().addDays(-2), OSF_End_Date__c = date.today().addDays(2),
                                                    OSF_Message_Sequence__c = 2));
                                   
        // add an old message valid message
        messageList.add(new OSF_Customer_Message__c(OSF_Message_Title__c =' Test Title 3', OSF_Message_Body__c = 'Test Body 3',
                                                    OSF_Start_Date__c = date.today().addDays(-14), OSF_End_Date__c = date.today().addDays(-7),
                                                    OSF_Message_Sequence__c = 3));

        insert messageList;
    }

    @isTest
    private static void testRetrieveValidMessage(){
        List<OSF_Customer_Message__c> messagesList =  OSF_CommunityPopUpMessageController.getCustomerMessages();

        Test.startTest();
        system.assertEquals(2, messagesList.size(), '2 valid messages should have been returned');
        Test.stopTest();
    }
}
