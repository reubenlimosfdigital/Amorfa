/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Test Class for OSF_StripeAdapter.
Test Class:    N/A
<Date>         <Authors Name>     <Brief Description of Change>
17-Oct-2022    Reuben Lim         Implemented test class for OSF_StripeAdapter
19-Oct-2022    Reuben Lim         Split out test methods to test for failure scenarios
------------------------------------------------------------*/
@isTest
private class OSF_StripeAdapterTest {

    @isTest
    static void testSuccessTokenizeResponse() {
        integer responseCode = 200;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeHttpMock(responseCode));
        generateTokenizeResponse(responseCode);
        Test.stopTest();
    }

    @isTest
    static void testFailureTokenizeResponse() {
        integer responseCode = 400;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeHttpMock(responseCode));
        generateTokenizeResponse(responseCode);
        Test.stopTest();
    }

    @isTest
    static void testSuccessAuthResponse() {
        integer responseCode = 200;
        insert new CardPaymentMethod(GatewayToken='pm_1234', status='Active', processingMode='External');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeHttpMock(responseCode));
        generateAuthResponse(responseCode);
        Test.stopTest();
    }

    @isTest
    static void testFailureAuthResponse() {
        integer responseCode = 400;
        insert new CardPaymentMethod(GatewayToken='pm_1234', status='Active', processingMode='External');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OSF_StripeHttpMock(responseCode));
        generateAuthResponse(responseCode);
        Test.stopTest();
    }

    private static void generateTokenizeResponse(integer statusCode) {
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.PaymentMethodTokenizationRequest paymentRequest = new commercepayments.PaymentMethodTokenizationRequest('paymentGatewayId');
        paymentRequest.address = new commercepayments.AddressRequest('66/62 Gov Macquarie Dr', 'Chipping Norton', 'New South Wales', 'Australia', '2170');
        paymentRequest.ipAddress = '127.0.0.1';
        paymentRequest.cardPaymentMethod = new commercepayments.CardPaymentMethodRequest(commercepayments.CardCategory.CreditCard);
        paymentRequest.cardPaymentMethod.cardHolderName = 'Daikin User';

        Map<String, String> additionalData = new Map<String, String>();
        additionalData.put('referrer','referrer test');
        additionalData.put('user_agent','user agent test');
        additionalData.put('payment_user_agent','payment user test');
        paymentRequest.additionalData = additionalData;

        //paymentGatewayContext params can be specified for test classes only
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(paymentRequest, commercepayments.RequestType.Tokenize);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
    }

    private static void generateAuthResponse(integer statusCode) {
        OSF_StripeAdapter adapter = new OSF_StripeAdapter();
        commercepayments.AuthorizationRequest authRequest = new commercepayments.AuthorizationRequest(100);
        commercepayments.AuthApiPaymentMethodRequest authPaymentReq = new commercepayments.AuthApiPaymentMethodRequest(new commercepayments.CardPaymentMethodRequest(commercepayments.CardCategory.CreditCard));

        authRequest.currencyIsoCode = 'AUD';
        authRequest.additionalData = new Map <String, String>{
            'token' => 'testToken'
        };
        authRequest.paymentMethod = authPaymentReq;

        //paymentGatewayContext params can be specified for test classes only
        commercepayments.paymentGatewayContext gatewayContext = new commercepayments.paymentGatewayContext(authRequest, commercepayments.RequestType.Authorize);
        commercepayments.GatewayResponse response = adapter.processRequest(gatewayContext);
    }

}