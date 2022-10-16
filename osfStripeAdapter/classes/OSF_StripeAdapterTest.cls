@isTest
private class OSF_StripeAdapterTest {

    @isTest
    static void testCreateAuthResponse() {

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new OSF_StripeAdapterMock());

        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.AuthorizationRequest authRequest = new commercepayments.AuthorizationRequest(100);
        commercepayments.AuthApiPaymentMethodRequest authPaymentReq = new commercepayments.AuthApiPaymentMethodRequest(new commercepayments.CardPaymentMethodRequest(commercepayments.CardCategory.CreditCard));

        // specify authorizationrequest properties, sets up the currency and token
        authRequest.currencyIsoCode = 'AUD';
        authRequest.additionalData = new Map <String, String>{
            'token' => 'testToken'
        };
        authRequest.paymentMethod = authPaymentReq;

        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(authRequest, commercepayments.RequestType.Authorize);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);

        Test.stopTest();
    }

    @isTest
    static void testCreateCaptureResponse() {
        
        //set the mock response
        Test.setMock(HttpCalloutMock.class, new OSF_StripeAdapterMock());

        Test.startTest();
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.CaptureRequest captureRequest = new commercepayments.CaptureRequest(1000, 'authIdTest');
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(captureRequest, commercepayments.RequestType.Capture);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }

    //no logic for test sale response from Salesforce
    @isTest
    static void testCreateSaleResponse() {
        
        Test.startTest();
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.SaleRequest saleRequest = new commercepayments.SaleRequest(1000);
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(saleRequest, commercepayments.RequestType.Sale);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }

    @isTest
    static void testCreateRefundResponse() {
        
        //set the mock response
        Test.setMock(HttpCalloutMock.class, new OSF_StripeAdapterMock());

        Test.startTest();
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.ReferencedRefundRequest refundRequest = new commercepayments.ReferencedRefundRequest(1000, 'paymentId');
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(refundRequest, commercepayments.RequestType.ReferencedRefund);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }

    @isTest 
    static void testCreateTokenizeResponse() {

        Test.setMock(HttpCalloutMock.class, new OSF_StripeAdapterMock());

        Test.startTest();
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.PaymentMethodTokenizationRequest paymentRequest = new commercepayments.PaymentMethodTokenizationRequest('paymentGatewayId');
        
        //set the payment details
        paymentRequest.address = new commercepayments.AddressRequest('66/62 Gov Macquarie Dr', 
                                                                      'Chipping Norton', 
                                                                      'New South Wales', 
                                                                      'Australia', 
                                                                      '2170');
        paymentRequest.ipAddress = '127.0.0.1';
        paymentRequest.cardPaymentMethod = new commercepayments.CardPaymentMethodRequest(commercepayments.CardCategory.CreditCard);
        paymentRequest.cardPaymentMethod.cardHolderName = 'Daikin User';

        Map<String, String> additionalData = new Map<String, String>();
        additionalData.put('referrer','referrer test');
        additionalData.put('user_agent','user agent test');
        additionalData.put('payment_user_agent','payment user test');
        paymentRequest.additionalData = additionalData;

        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(paymentRequest, commercepayments.RequestType.Tokenize);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }

    @isTest
    static void testCreateAuthReversalResponse() {
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeAdapterMock());
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();

        commercepayments.AuthorizationReversalRequest authReversalRequest = new commercepayments.AuthorizationReversalRequest(1000, 'authId');
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(authReversalRequest, commercepayments.RequestType.AuthorizationReversal);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
        Test.stopTest();
    }

}