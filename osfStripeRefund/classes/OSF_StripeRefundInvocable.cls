/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   The invocable method to refund a Stripe payment. Requires a singular
               Payment Record Id.
Test Class:    
<Date>         <Authors Name>     <Brief Description of Change>
26-Jan-2023    Reuben Lim         First implemented
13-Feb-2023    Reuben Lim         Removed references to a Util class and just put everything in here.
------------------------------------------------------------*/

public class OSF_StripeRefundInvocable {

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

    @InvocableMethod(label = 'Process a Stripe Refund' 
    description = 'An invocable to refund a Stripe Payment. Requires a single Payment record id.')
    public static void refundStripePaymentWithRefundAndPaymentRecords (List<OSF_StripeRefundInputWrapper> inputs) {

        OSF_StripeRefundInputWrapper input = inputs[0];

        //callout to Stripe to capture payment
        processStripeRefund(input.refundRecordId, input.paymentRecordId);
    }

    //used to feed in the refund record id and the payment record id
    public class OSF_StripeRefundInputWrapper {

        @InvocableVariable
        public Id refundRecordId;
        
        @InvocableVariable
        public Id paymentRecordId;

    }

    //perform a refund process
    @future(callout=true)
    public static void processStripeRefund(Id refundRecordId, Id paymentRecordId) {

        //retrieve the records
        //i could optimise this but it helps with readability for now
        Refund refund = [SELECT id, amount, currencyIsoCode FROM Refund WHERE Id =: refundRecordId];
        Payment payment = [SELECT id, PaymentAuthorizationId FROM Payment WHERE id =: paymentRecordId];
        PaymentAuthorization pa = [SELECT id, GatewayRefNumber, PaymentGatewayId, OrderPaymentSummaryId FROM PaymentAuthorization WHERE id =: payment.PaymentAuthorizationId];

        //grab the named credentials for the callout. this is based on the payment authorization record which has the gateway
        String namedCredential = [SELECT MerchantCredential.DeveloperName FROM PaymentGateway WHERE id =:pa.PaymentGatewayId LIMIT 1][0].MerchantCredential.DeveloperName;

        Map<String, String> params = New Map<String, String>();
        params.put('payment_intent', pa.GatewayRefNumber);
        params.put('amount', toStripeCurrencyUnits(refund.currencyIsoCode, (Double) refund.amount));

        //callout to stripe
        HttpResponse res = doPost(namedCredential, 'refunds', params); 

        //retrieve responses
        Integer sc = res.getStatusCode();
        Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

        //create the capture log record
        PaymentGatewayLog pgl = new PaymentGatewayLog(interactionType = 'ReferencedRefund');
        insert pgl;

        // start logging
        pgl.request = urlEncodedParams(params);
        pgl.response = res.getBody();
        pgl.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);
        pgl.gatewayDate = System.now();
        pgl.ReferencedEntityId = refund.id;
        pgl.orderPaymentSummaryId = pa.OrderPaymentSummaryId;

        //update refund record
        refund.PaymentGatewayId = pa.PaymentGatewayId;
        refund.gatewayDate = System.now();
        refund.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);

        if (sc == 200) {
            pgl.interactionStatus = 'Success';
            pgl.SfResultCode = 'Success';
            pgl.GatewayRefNumber = (String) body.get('id');
            
            //update refund details
            refund.status = 'Processed'; 
            refund.SfResultCode = 'Success';
            refund.GatewayRefNumber = (String) body.get('id');
            
        } else {
            
            //log all information on a failed capture
            Map<String, Object> error = (Map<String, Object>) body.get('error');
            String errorType = (String) error.get('type');
            String errorCode = (String) error.get('code');
            
            pgl.interactionStatus = 'Failed';
            pgl.GatewayResultCodeDescription = (errorType + (errorCode != null ? ': ' + errorCode : '')).left(1000); //1000 
            pgl.GatewayMessage = ((String) error.get('message')).left(255);

            //update refund details
            refund.SfResultCode = 'PermanentFail';
            refund.GatewayResultCodeDescription = (errorType + (errorCode != null ? ': ' + errorCode : '')).left(1000); //1000 
        }

        update refund;
        update pgl;

        // so theres some weird things with the way salesforce does refunds
        // we can only create the refund lines after the refund is set to "Processed"
        // also, we can't update the refund after the status is set to failed.
        if (sc == 200) {
            createRefundLinePaymentRecord(refund.id, payment.id, refund.amount);
        } else {
            refund.status = 'Failed'; 
            update refund;
        }

    }

    // all refunds are based on payments
    private static void createRefundLinePaymentRecord(Id refundRecordId, Id paymentRecordId, Decimal amount) {

        Refund refund = [SELECT id, CurrencyIsoCode FROM Refund WHERE id =: refundRecordId];

        RefundLinePayment rlp = new RefundLinePayment();
        rlp.refundId = refundRecordId;
        rlp.type = 'Applied';
        rlp.paymentId = paymentRecordId;
        rlp.amount = amount;
        rlp.currencyIsoCode = refund.currencyIsoCode;
        rlp.date = System.now();

        insert rlp;

    }

    //calls out to stripe. also sets the usual callout settings
    private static HttpResponse doPost(String namedCredential, String path, Map<String, String> params) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + namedCredential + '/v1/' + path);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        if (params == null) {
            request.setBody('{ }');
        } else {
            request.setBody(urlEncodedParams(params));
        }
        
        return http.send(request);
    }

    //stripe requires the params to be url encoded
    private static String urlEncodedParams(Map<String, String> params) {
        String body = '';
        Boolean first = true;
        for (String key: params.keySet()) {
            if (first) {
                first = false;
            } else {
                body += '&';
            }
            // NOTE: do not encode values to allow PaymentsNamedConnection to replace the secure fields
            // values that need to be encoded should be encoded by this method's caller
            body += urlEncode(key) + '=' + params.get(key);
        }
        return body;
    }

    private static String urlEncode(String str) {
        return EncodingUtil.urlEncode(str, 'UTF-8');
    }

    private static String toStripeCurrencyUnits(String currencyIsoCode, Double amount) {
        // see https://stripe.com/docs/currencies#zero-decimal

        String currencyCodeLC = currencyIsoCode.toLowercase();
        Decimal decimalScaledAmount = Decimal.ValueOf(amount).setScale(2);

        if (ZERO_DECIMAL_CURRENCY.contains(currencyCodeLC)) {
            return String.ValueOf((amount).intValue());
        } else if (currencyCodeLC.equals('huf')) {
            return String.ValueOf((decimalScaledAmount * 100).intValue());
        }

        return String.ValueOf((decimalScaledAmount * 100).intValue());
    }

    private static commercepayments.SalesforceResultCodeInfo toCodeInfo(commercepayments.SalesforceResultCode code) {
        return new commercepayments.SalesforceResultCodeInfo(code);
    }

}