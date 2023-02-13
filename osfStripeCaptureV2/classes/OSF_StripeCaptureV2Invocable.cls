/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   The invocable method to capture a Stripe payment. Requires a singular
               Payment Record Id.
Test Class:    OSF_StripeCaptureV2InvocableTest
<Date>         <Authors Name>     <Brief Description of Change>
26-Jan-2023    Reuben Lim         First implemented
13-Feb-2023    Reuben Lim         Removed references to a Util class and just put everything in here.
------------------------------------------------------------*/

public class OSF_StripeCaptureV2Invocable {
    private static final commercepayments.SalesforceResultCodeInfo RC_SUCCESS = toCodeInfo(commercepayments.SalesforceResultCode.Success);
    private static final commercepayments.SalesforceResultCodeInfo RC_DECLINE = toCodeInfo(commercepayments.SalesforceResultCode.Decline);
    private static final commercepayments.SalesforceResultCodeInfo RC_REQUIRES_REVIEW = toCodeInfo(commercepayments.SalesforceResultCode.RequiresReview);
    private static final commercepayments.SalesforceResultCodeInfo RC_VALIDATION_ERROR = toCodeInfo(commercepayments.SalesforceResultCode.ValidationError);
    private static final List<String> DECLINE_CODES = new List<String>{'card_declined', 'incorrect_cvc', 'expired_card',
     'authentication_required', 'card_not_supported', 'currency_not_supported', 'incorrect_number', 'incorrect_zip'};
    // see https://stripe.com/docs/currencies#zero-decimal
    private static final List<String> ZERO_DECIMAL_CURRENCY = new List<String>{
        'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga',
        'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf'};
    private static final Map<Integer, String> HTTP_STATUS_CODE_VALUES = new Map<Integer, String>{
        200 =>'OK', 400 =>'Bad Request', 401 =>'Unauthorized', 402 =>'Request Failed', 403 =>'Forbidden',
        404 =>'Not Found', 409 =>'Conflict', 429=> 'Too Many Requests', 500=>'Server Error'};

    @InvocableMethod(label = 'Capture a Stripe Payment v2' 
    description = 'An updated invocable to capture a Stripe Payment. Requires a single Payment record id.')
    public static void captureStripePaymentWithPaymentAuthId (List<ID> paymentRecordId) {

        //grab the payment record
        Payment payment = [SELECT id, PaymentAuthorizationId FROM Payment WHERE id =: paymentRecordId[0] LIMIT 1];
        
        //link previous logs
        linkOtherPaymentGatewayLogsToPaymentOrderSummary(payment.PaymentAuthorizationId);

        //callout to Stripe to capture payment
        processStripePayment(payment.id);
    }

    //perform a capture process
    @future(callout=true)
    public static void processStripePayment(id paymentRecordId) {

        //retrieve the records
        Payment payment = [SELECT id, PaymentAuthorizationId FROM Payment WHERE Id =: paymentRecordId];
        PaymentAuthorization pa = [SELECT id, GatewayRefNumber, OrderPaymentSummaryId, PaymentMethodId, 
                                   paymentGroupId, CurrencyIsoCode, PaymentGatewayId FROM PaymentAuthorization WHERE Id =: payment.PaymentAuthorizationId LIMIT 1];

        //grab the named credentials for the callout. this is based on the payment authorization record which has the gateway
        String namedCredential = [SELECT MerchantCredential.DeveloperName FROM PaymentGateway WHERE id =:pa.PaymentGatewayId LIMIT 1][0].MerchantCredential.DeveloperName;

        //callout to stripe
        HttpResponse res = doPost(namedCredential, 'payment_intents/' +  pa.GatewayRefNumber + '/capture', null);

        //retrieve responses
        Integer sc = res.getStatusCode();
        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

        //create the capture log record
        PaymentGatewayLog pgl = new PaymentGatewayLog(interactionType = 'Capture');
        insert pgl;

        // start logging
        pgl.request = '{ }'; // no body required for payment capture
        pgl.response = res.getBody();
        pgl.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);
        pgl.gatewayDate = System.now();
        pgl.ReferencedEntityId = pa.id;
        pgl.orderPaymentSummaryId = pa.OrderPaymentSummaryId;

        //update payment record
        payment.PaymentGatewayId = pa.PaymentGatewayId;
        payment.gatewayDate = System.now();
        payment.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);

        if (sc == 200) {
            //log all information on a sucessful capture
            Map<String, Object> charges = (Map<String, Object>)body.get('charges');
            List<Object> datas = (List<Object>) charges.get('data');
            Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(datas[0]));    

            pgl.interactionStatus = 'Success';
            pgl.SfResultCode = 'Success';
            
            //update payment details
            payment.status = 'Processed'; 
            payment.SfResultCode = 'Success';
            payment.GatewayRefNumber = (String)data.get('id');

        } else {
            //log all information on a failed capture
            Map<String, Object> error = (Map<String, Object>) body.get('error');
            String errorType = (String) error.get('type');
            String errorCode = (String) error.get('code');
            
            pgl.interactionStatus = 'Failed';
            pgl.GatewayResultCodeDescription = (errorType + (errorCode != null ? ': ' + errorCode : '')).left(1000); //1000 
            pgl.GatewayMessage = ((String) error.get('message')).left(255);

            //update payment details
            payment.status = 'Failed'; 
            payment.SfResultCode = 'PermanentFail';
            payment.GatewayResultCodeDescription = (errorType + (errorCode != null ? ': ' + errorCode : '')).left(1000); //1000 
        }
        
        update payment;
        update pgl;
    }

    //calls out to stripe. also sets the usual callout settings
    private static HttpResponse doPost(String namedCredential, String path, Map<String, String> params) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + namedCredential + '/v1/' + path);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        // callouts for capture requires no body
        if (params == null) {
            request.setBody('{ }');
        } 
        
        return http.send(request);
    }

    private static commercepayments.SalesforceResultCodeInfo toCodeInfo(commercepayments.SalesforceResultCode code) {
        return new commercepayments.SalesforceResultCodeInfo(code);
    }


    public static void linkOtherPaymentGatewayLogsToPaymentOrderSummary(Id paymentAuthRecordId) {
        
        //retrieve the record
        PaymentAuthorization pa = [SELECT id, PaymentMethodId, OrderPaymentSummaryId FROM PaymentAuthorization WHERE Id =: paymentAuthRecordId LIMIT 1];

        // only appends successful logs, unsuccesful ones dont have reference sorted
        List<PaymentGatewayLog> pglListToUpdate = new List<PaymentGatewayLog>();

        // retrieve authorization log, link it to the order payment summary
        // successful logs has the reference link to the payment authorisation
        PaymentGatewayLog pglAuth = [SELECT id, OrderPaymentSummaryId FROM PaymentGatewayLog WHERE InteractionType = 'Authorization' AND ReferencedEntityId =: pa.id LIMIT 1];

        if (pglAuth != null) {
            pglAuth.OrderPaymentSummaryId = pa.OrderPaymentSummaryId;
            pglListToUpdate.add(pglAuth);
        }
            
        //retrieve tokenization log, link it to the order payment summary
        // successful logs has the reference link to the payment method
        PaymentGatewayLog  pglToken = [SELECT id, OrderPaymentSummaryId FROM PaymentGatewayLog WHERE InteractionType = 'Tokenize' AND ReferencedEntityId =: pa.paymentMethodId LIMIT 1];
        
        if (pglToken != null) {
        	pglToken.OrderPaymentSummaryId = pa.OrderPaymentSummaryId;
        	pglListToUpdate.add(pglToken);
        }

        if (pglListToUpdate.size() > 0) {
        	update pglListToUpdate;
        }
    }
}