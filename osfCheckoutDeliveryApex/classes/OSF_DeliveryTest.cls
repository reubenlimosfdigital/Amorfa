/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Retrieves the appropriate Order Delivery Methods for Checkout.
               Can be used for both B2B and D2C storefronts. Update the test class
               with the appropriate test data setup.
Test Class:    OSF_B2BDeliveryTest
<Date>         <Authors Name>     <Brief Description of Change>
21-Nov-2022    Reuben Lim         Implemented for Hello Medical
30-Nov-2022    Dan Payne          Updated references from Account fields to PersonAccount fields
19-Jun-2023	   Reuben Lim	      Renamed classes and tidied up for future use
20-Jun-2023	   Reuben Lim	      Added in more notes for B2B and D2C scenarios
                                  Added in test for generic exception handling
------------------------------------------------------------*/
@isTest
private class OSF_DeliveryTest {

    @testSetup 
    static void setup() {

        /*  
            -----------------------------------------------------------------
            The test class must be updated to accommodate a B2B or D2C scenario.
            B2B storefronts use Standard Accounts whilst D2C uses Person Accounts.
            Update the test data setup with the creation of either or.

            CREATES A STANDARD ACCOUNT
            --------------------------
            Account a = new Account(name='Test OSF Commerce Account');
            insert a;

            CREATES A PERSON ACCOUNT
            ------------------------
            Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
    
            Account a = new Account(LastName='TestAccount', recordTypeId=personAccountRecordTypeId);
            insert a;
            ----------------------------------------------------------------- 
        */

        // ---- UPDATE ACCOUNT OR PERSON ACCOUNT CREATION HERE ---- 
        Account a = new Account(name='Test OSF Commerce Account');
        insert a;
        
        // ---- UPDATE STOREFRONT TYPE HERE ---- 
        WebStore testWebStore = new WebStore(Name='TestWebStore', SupportedLanguages='en_US', DefaultLanguage='en_US', type='B2B');
        insert testWebStore;
        
        WebCart cart = new WebCart(Name='Cart', WebStoreId=testWebStore.Id, AccountId=a.Id);
        insert cart;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery 1');
        insert cartDeliveryGroup;

        CartItem cartItem = new CartItem(CartId=cart.Id, Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id, TotalLineAmount=100);
        insert cartItem;
        
    }
    
    // creates 2 Order Delivery Method records and expects 1 valid record back
    @isTest 
    static void testSuccessCriteria() {
        
        OSF_Delivery deliveryApexClass = new OSF_Delivery();
        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;
        
        WebCart webCart = [SELECT Id, WebStoreId FROM WebCart WHERE Name='Cart' LIMIT 1];
        List<OrderDeliveryMethod> odmList = new List<OrderDeliveryMethod>();
        
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        odmList.add(new OrderDeliveryMethod(Name='ODM not valid', isActive=false, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
    
        insert odmList;
        
        Test.startTest();
        sfdc_checkout.IntegrationStatus integrationResult = deliveryApexClass.startCartProcessAsync(integInfo, webCart.Id);
        // Checks for successful insert of CDGM records
        List<CartDeliveryGroupMethod> cdgmList = [SELECT id FROM CartDeliveryGroupMethod WHERE WebCartId = :webCart.id];
        System.assertEquals(1, cdgmList.size());
        // Checks for a successful response
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status);
        Test.stopTest();
    }
    
    // creates no Order Delivery Group Methods to throw and test exceptions
    @isTest 
    static void testExceptionHandling() {
        
        OSF_Delivery deliveryApexClass = new OSF_Delivery();
        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;
        
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        
        Test.startTest();        
        sfdc_checkout.IntegrationStatus integrationResult = deliveryApexClass.startCartProcessAsync(integInfo, webCart.Id);
        
        // Validate: IntegrationStatus.Status is FAILED
        // and a new CartValidationOutput record with level 'Error' was created.
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id FROM CartValidationOutput WHERE Level = 'Error'];
        System.assertEquals(1, cartValidationOutputs.size());
        Test.stopTest();
    }
    
    // tests DML insert error
    // there is a check in the main class that looks for isRunningTest and 3 ODM records
	@isTest 
    static void testDMLExceptionHandling() {
        
        OSF_Delivery deliveryApexClass = new OSF_Delivery();
        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;
        
        WebCart webCart = [SELECT Id, WebStoreId FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        
        List<OrderDeliveryMethod> odmList = new List<OrderDeliveryMethod>();
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        insert odmList;

        Test.startTest();        
        sfdc_checkout.IntegrationStatus integrationResult = deliveryApexClass.startCartProcessAsync(integInfo, webCart.Id);
        
        // Validate: IntegrationStatus.Status is FAILED
        // and a new CartValidationOutput record with level 'Error' was created.
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id FROM CartValidationOutput WHERE Level = 'Error'];
        System.assertEquals(1, cartValidationOutputs.size());
        Test.stopTest();
    }

    // tests DML insert error
    // there is a check in the main class that looks for isRunningTest and 4 ODM records
    @isTest 
    static void testGenericExceptionHandling() {
        
        OSF_Delivery deliveryApexClass = new OSF_Delivery();
        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;
        
        WebCart webCart = [SELECT Id, WebStoreId FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        
        List<OrderDeliveryMethod> odmList = new List<OrderDeliveryMethod>();
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        odmList.add(new OrderDeliveryMethod(Name='ODM valid', isActive=true, Carrier='Hare Carriers', OSF_Store__c=webCart.webstoreId));
        insert odmList;

        Test.startTest();        
        sfdc_checkout.IntegrationStatus integrationResult = deliveryApexClass.startCartProcessAsync(integInfo, webCart.Id);
        
        // Validate: IntegrationStatus.Status is FAILED
        // and a new CartValidationOutput record with level 'Error' was created.
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id FROM CartValidationOutput WHERE Level = 'Error'];
        System.assertEquals(1, cartValidationOutputs.size());
        Test.stopTest();
    }

}