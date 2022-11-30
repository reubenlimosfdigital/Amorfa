/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Test Class for OSF_B2CStripeAdapter.
Test Class:    N/A
<Date>         <Authors Name>     <Brief Description of Change>
17-Oct-2022    Reuben Lim         Implemented test class for OSF_StripeCapturePaymentIntent
30-Nov-2022    Reuben Lim         Removed redundant test function.
                                  Added in creation of test PaymentGatewayProvider and NamedCredential
                                  test data. 
                                  Update PaymentAuthorization record to refer to the CardPaymentMethod record
------------------------------------------------------------*/
@isTest(SeeAllData=true)
private class OSF_StripeCapturePaymentIntentTest {
        
    @isTest
    static void testSuccessCapturePaymentIntent() {
        integer responseCode = 200;
        generateOrderSummaryTestRecord();
 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeHttpMock(responseCode));
        generateCapturePaymentIntent(responseCode);
        Test.stopTest();
    }
    
    @isTest
    static void testFailureCapturePaymentIntent() {
        integer responseCode = 400;
        generateOrderSummaryTestRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeHttpMock(responseCode));
        generateCapturePaymentIntent(responseCode);
        Test.stopTest();
    }
    
    private static void generateCapturePaymentIntent(integer statusCode) {
        List<PaymentAuthorization> paList = [SELECT id from PaymentAuthorization];
        OSF_StripeCapturePaymentIntent.capturePaymentIntent(paList);
    }
    
    // generates a test Order Summary and returns the record id
    @TestVisible
    private static id generateOrderSummaryTestRecord() {
        
        //generate test account
        Account a = new Account(name = 'Test Account');
        insert a;
        
        //generate test contact
        Contact c = new Contact(accountId = a.id, firstName = 'Test', lastName = 'Contact');
        insert c;
        
        //generate product
        Product2 p = new Product2(name = 'Test Product', isActive = true, productCode = 'TEST');
        insert p;
        
        //generate new pricebook
        Pricebook2 pb = new Pricebook2(name = 'Test Pricebook', isActive = true);
        insert pb;
        
        //add product to standard price book.
		insert new PriceBookEntry(pricebook2Id = Test.getStandardPricebookId(), product2Id = p.id, isActive = true, unitPrice = 100);
        
        //add product to new pricebook
		PricebookEntry pbe = new PriceBookEntry(Pricebook2Id = pb.id, product2Id = p.id, isActive = true, unitPrice = 100);
		insert pbe;
        
        //generate order
        Order o = new Order(accountId = a.id, effectiveDate = Date.today(), status = 'Draft', pricebook2Id = pb.id);
        insert o;
        
        //generate order delivery group method
        OrderDeliveryMethod odm = new OrderDeliveryMethod(Name = 'Test Order Delivery Method', isActive = true);
        insert odm;
        
        // generate order delivery group
        OrderDeliveryGroup odg = new OrderDeliveryGroup(orderId = o.id, OrderDeliveryMethodId = odm.id, DeliverToName = 'Test Deliver To');
        insert odg;
                
        //add order items
        OrderItem oi = new OrderItem();
        oi.OrderId = o.id;
        oi.Product2Id = p.Id;
        oi.PricebookEntryId = pbe.id;
        oi.OrderDeliveryGroupId = odg.id;
        oi.Quantity = 10;
        oi.UnitPrice = 100;
        oi.TotalLineAmount = 1000;
        insert oi;
        
        //activate the order prior to generating the order summary
        o.status = 'Activated';
        update o;
        
        //generate order summary
        //this is the reason we need SeeAllData=true. You can't generate the order summary without it
        ConnectApi.OrderSummaryInputRepresentation osInput = new ConnectApi.OrderSummaryInputRepresentation();
        
        osInput.orderId = o.id;
        osInput.orderLifeCycleType = 'UNMANAGED';
        
        ConnectApi.OrderSummaryOutputRepresentation osOutput = ConnectApi.OrderSummaryCreation.createOrderSummary(osInput);

        //updated to include order payment summary data
        CardPaymentMethod cpm = new CardPaymentMethod(GatewayToken='pm_', status='Active', processingMode='External');
        insert cpm;

        PaymentGatewayProvider pgp = [SELECT Id FROM PaymentGatewayProvider LIMIT 1];
        NamedCredential nc = [SELECT Id FROM NamedCredential LIMIT 1];

        PaymentGateway pg = new PaymentGateway(PaymentGatewayName='Test Payment Gateway', Status='Active', PaymentGatewayProviderId=pgp.id, MerchantCredentialId=nc.id);
        insert pg;
            
        PaymentAuthorization pa = new PaymentAuthorization(amount=100, status='Processed', currencyIsoCode='AUD', processingMode='External', PaymentGatewayId=pg.id, paymentMethodId=cpm.id);
        insert pa;
        
        PaymentGatewayLog pglToken = new PaymentGatewayLog(interactionType='Tokenize', ReferencedEntityId=cpm.id);
        insert pglToken;
        
        PaymentGatewayLog pglAuth = new PaymentGatewayLog(interactionType='Authorization', ReferencedEntityId=pa.id, gatewayAuthCode='pi_3LuTRlKgY5eOD51n00k7lXHs');
        insert pglAuth;
        
        OrderPaymentSummary ops = new OrderPaymentSummary(method=cpm.id, orderSummaryId=osOutput.orderSummaryId, type='Visa');
        insert ops;        
        
        return osOutput.orderSummaryId;
    }


}