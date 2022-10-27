/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   An invocable method to perform a Stripe Capture Payment Intent API call.
               Meant to be used in an async flow on creation of a new Order Summary record.
               Takes a Payment Authorization record, assumes it has the gatewayAuthCode as the
               Stripe payment_intent id.
Test Class:    OSF_StripeCapturePaymentIntent
<Date>         <Authors Name>     <Brief Description of Change>
19-Oct-2022    Reuben Lim         First implemented
27-Oct-2022    Reuben Lim         Made the named credential callout dynamic based on the Payment Auth record
------------------------------------------------------------*/

public class OSF_StripeCapturePaymentIntent {

    private static final List<String> ZERO_DECIMAL_CURRENCY = new List<String>{
        'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga',
        'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf'};
    private static final Map<Integer, String> HTTP_STATUS_CODE_VALUES = new Map<Integer, String>{
        200 =>'OK', 400 =>'Bad Request', 401 =>'Unauthorized', 402 =>'Request Failed', 403 =>'Forbidden',
        404 =>'Not Found', 409 =>'Conflict', 429=> 'Too Many Requests', 500=>'Server Error'};
    
    @InvocableMethod(label = 'Capture a Payment based on a Payment Authorization record.' 
                     description = 'Performs a payment capture callout to Stripe using the Payment Intent id field on the Payment Authorisation record. A successful capture creates the Payment record, a Capture Payment Gateway Log and relinks the other related logs')
    public static void capturePaymentIntent(List<PaymentAuthorization> paList) {

        //create the log immediately, then populate as we go on
        PaymentGatewayLog pgl = new PaymentGatewayLog(interactionType = 'Capture');
        insert pgl;
        
        //assume only 1 payment authorization record
        PaymentAuthorization pa = paList[0];
        callStripeCapturePaymentIntentsEndpoint(pa.id, pgl.id);
    }
    
    @future(callout=true)
    private static void callStripeCapturePaymentIntentsEndpoint(id paymentAuthId, id paymentGatewayLogId) {
		//https://stripe.com/docs/api/payment_intents
        PaymentAuthorization pa = [SELECT id, GatewayAuthCode, OrderPaymentSummaryId, PaymentMethodId, paymentGroupId, CurrencyIsoCode, PaymentGatewayId FROM PaymentAuthorization WHERE Id =: paymentAuthId LIMIT 1];
        PaymentGatewayLog pgl = [SELECT id FROM PaymentGatewayLog WHERE id =: paymentGatewayLogId LIMIT 1];

        //grab the named credentials for the callout. this is based on the payment authorization record which has the gateway
        String namedCredential = [SELECT MerchantCredential.DeveloperName FROM PaymentGateway WHERE id =:pa.PaymentGatewayId LIMIT 1][0].MerchantCredential.DeveloperName;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + namedCredential + '/v1/payment_intents/' +  pa.gatewayAuthCode + '/capture' );
        req.setMethod('POST');
        req.setBody('{}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        Integer sc = res.getStatusCode();
        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

        pgl.request = req.getBody();
        pgl.response = res.getBody();
        pgl.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);
        pgl.gatewayDate = System.now();
        pgl.ReferencedEntityId = pa.id;
        pgl.orderPaymentSummaryId = pa.OrderPaymentSummaryId;

        if (sc == 200) {
            
            // needs a shitton of error handling
            Map<String, Object> charges = (Map<String, Object>)body.get('charges');
            List<Object> datas = (List<Object>) charges.get('data');
            Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(datas[0]));    

            // log all information on a sucessful capture
            pgl.interactionStatus = 'Success';
            pgl.SfResultCode = 'Success';

            // create payment record        
            Payment payment = new Payment();
            payment.type = 'Capture';
            payment.status = 'Processed';
            payment.processingMode = 'External';
            payment.SfResultCode = 'Success';
            payment.amount = fromStripeCurrencyUnits(pa.currencyIsoCode, (Integer)body.get('amount')); // need to use the from and to for stripe;
            payment.currencyIsoCode = pa.currencyIsoCode;
            payment.paymentAuthorizationId = pa.id;
            payment.paymentMethodId = pa.PaymentMethodId;
            payment.paymentGroupId = pa.paymentGroupId;
            payment.date = System.now(); 
            payment.effectiveDate = System.now();
            payment.gatewayDate = System.now();
            payment.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);
            payment.orderPaymentSummaryId = pa.OrderPaymentSummaryId;
            //payment.OSF_Capture_Receipt_URL__c = (String)data.get('receipt_url');
            insert payment;
        } else {
            // log all information on a failed capture
            Map<String, Object> error = (Map<String, Object>) body.get('error');
            
            pgl.interactionStatus = 'Failed';
            //pgl.SfResultCode = 'SystemError';
            
            String errorType = (String) error.get('type');
            String errorCode = (String) error.get('code');
            
            pgl.GatewayResultCodeDescription = (errorType + (errorCode != null ? ': ' + errorCode : '')).left(1000); //1000 
            pgl.GatewayMessage = ((String) error.get('message')).left(255);
        }
        
        update pgl;
        linkOtherPaymentGatewayLogsToPaymentOrderSummary(pa);
    }
    
    private static Double fromStripeCurrencyUnits(String currencyIsoCode, Long amount) {

        if (ZERO_DECIMAL_CURRENCY.contains(currencyIsoCode.toLowercase())) {
            return (Double)amount;
        }

        return ((Double)amount / 100.0);
    }
    
    private static void linkOtherPaymentGatewayLogsToPaymentOrderSummary(PaymentAuthorization pa) {
        // only appends successful logs, unsuccesful ones dont have reference sorted
        List<PaymentGatewayLog> pglListToUpdate = new List<PaymentGatewayLog>();

        // retrieve authorization log, link it to the order payment summary
        // successful logs has the reference link to the payment authorisation
        PaymentGatewayLog pglAuth = [SELECT id, OrderPaymentSummaryId FROM PaymentGatewayLog WHERE InteractionType = 'Authorization' AND ReferencedEntityId =: pa.id LIMIT 1];
        system.debug('debug');
        
        system.debug(pglAuth);
        
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