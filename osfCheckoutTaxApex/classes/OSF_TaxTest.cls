/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Calculates tax on all Cart Item records on the Cart.
               Can be used for both B2B and D2C storefronts. The calculation to work out
               tax varies between B2B (Net) vs D2C (Gross).
Test Class:    OSF_TaxTest
<Date>         <Authors Name>     <Brief Description of Change>
20-Jun-2023    Reuben Lim         Updated to make work for B2B and D2C scenarios
------------------------------------------------------------*/
@isTest
public class OSF_TaxTest {
    
    @testSetup
    static void setup() {

        // set up the B2B / B2C store
        List<String> storeTypeList = New List<String>{'B2B','B2C'};

        for (String storeType : storeTypeList ) {
            
            Account account = new Account(Name='TestAccount' + storeType , BillingCity='sydney',BillingCountry='Aus',BillingStreet='123',BillingPostalCode='4000');
            insert account;

            WebStore webStore = new WebStore(Name='TestWebStore', SupportedLanguages='en_US', DefaultLanguage='en_US', type=storeType);
            insert webStore;

            WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id, CurrencyISOCode = 'AUD');
            insert cart;
            
            CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
            insert cartDeliveryGroup;
            
            CartItem productCartItem = new CartItem(
                CartId=cart.Id, 
                Sku='SKU_Test1', 
                Quantity=3.0, 
                Type='Product', 
                Name='TestProduct', 
                CartDeliveryGroupId=cartDeliveryGroup.Id,
                CurrencyISOCode = 'AUD'
            );
            insert productCartItem;

            CartItem chargeCartItem = new CartItem(
                CartId=cart.Id, 
                Sku='SKU_Test1', 
                Quantity=1.0, 
                Type='Charge', 
                Name='TestProduct', 
                CartDeliveryGroupId=cartDeliveryGroup.Id,
                CurrencyISOCode = 'AUD'
            );
            insert chargeCartItem;
        }
       
    }
    
    @isTest
    static void testCartTaxForCartItemSuccessfullyInsertedOnB2B() {

        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;

        Test.startTest();
        OSF_Tax taxApexClass = new OSF_Tax();

        // retrieve ids for testing purposes
        WebCart cart = [SELECT Id FROM WebCart WHERE Name = 'Cart' AND WebStore.Type = 'B2B'];
        List<CartItem> ciList = [SELECT id FROM CartItem WHERE cartId =: cart.id];

        // trigger tax calculations and test for success
        sfdc_checkout.IntegrationStatus integrationResult = taxApexClass.startCartProcessAsync(integInfo, cart.id);
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status);

        // check for tax calculations
        List<CartTax> cartTaxes = [SELECT Id FROM CartTax WHERE CartItem.CartId =: cart.id];
        System.assertEquals(2, cartTaxes.size());

        Test.stopTest();
    }

    @isTest
    static void testCartTaxForCartItemSuccessfullyInsertedOnD2C() {

        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;

        Test.startTest();
        OSF_Tax taxApexClass = new OSF_Tax();

        // retrieve ids for testing purposes
        WebCart cart = [SELECT Id, webstore.type FROM WebCart WHERE Name = 'Cart' AND WebStore.Type = 'B2C'];
        List<CartItem> ciList = [SELECT id FROM CartItem WHERE cartId =: cart.id];

        // trigger tax calculations and test for success
        sfdc_checkout.IntegrationStatus integrationResult = taxApexClass.startCartProcessAsync(integInfo, cart.id);
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status);

        // check for tax calculations
        List<CartTax> cartTaxes = [SELECT Id FROM CartTax WHERE CartItem.CartId =: cart.id];
        System.assertEquals(2, cartTaxes.size());

        Test.stopTest();
    }

    
    @isTest
    static void testNoCartItemB2B() {

        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;

        Test.startTest();
        OSF_Tax taxApexClass = new OSF_Tax();

        // retrieve ids for testing purposes
        WebCart cart = [SELECT Id, webstore.type FROM WebCart WHERE Name = 'Cart' AND WebStore.Type = 'B2B'];
        delete [SELECT id FROM CartItem];

        // trigger tax calculations and test for success
        sfdc_checkout.IntegrationStatus integrationResult = taxApexClass.startCartProcessAsync(integInfo, cart.id);
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);

        Test.stopTest();
    }
 
    @isTest
    static void testNoCartItemB2C() {

        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;

        Test.startTest();
        OSF_Tax taxApexClass = new OSF_Tax();

        // retrieve ids for testing purposes
        WebCart cart = [SELECT Id, webstore.type FROM WebCart WHERE Name = 'Cart' AND WebStore.Type = 'B2C'];
        delete [SELECT id FROM CartItem];

        // trigger tax calculations and test for success
        sfdc_checkout.IntegrationStatus integrationResult = taxApexClass.startCartProcessAsync(integInfo, cart.id);
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        
        Test.stopTest();
    }

    @isTest
    static void testNoCartItemB2C() {

        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;

        Test.startTest();
        OSF_Tax taxApexClass = new OSF_Tax();

        // retrieve ids for testing purposes
        WebCart cart = [SELECT Id, webstore.type FROM WebCart WHERE Name = 'Cart' AND WebStore.Type = 'B2C'];
        delete [SELECT id FROM CartItem];

        // trigger tax calculations and test for success
        sfdc_checkout.IntegrationStatus integrationResult = taxApexClass.startCartProcessAsync(integInfo, cart.id);
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        
        Test.stopTest();
    }

    
}