public class OSF_StripeCapturePaymentIntent {

    private static final Map<Integer, String> HTTP_STATUS_CODE_VALUES = new Map<Integer, String>{
        200 =>'OK', 400 =>'Bad Request', 401 =>'Unauthorized', 402 =>'Request Failed', 403 =>'Forbidden',
        404 =>'Not Found', 409 =>'Conflict', 429=> 'Too Many Requests', 500=>'Server Error'};

    @InvocableMethod(label = 'Capture a Payment based on a Payment Authorization record.' 
                     description = 'Performs a payment capture callout to Stripe using the Payment Intent id field on the Payment Authorisation record. A successful capture creates the Payment record, a Capture Payment Gateway Log and relinks the other related logs')
    public static void capture(List<PaymentAuthorization> paList) {

        Id paId = paList[0].id;
        callStripeCaptureEndpoint(paId);

        // only appends successful logs, unsuccesful ones dont do jack

        List<PaymentGatewayLog> pglListToUpdate = new List<PaymentGatewayLog>();

        // retrieve authorization log, link it to the order payment summary
        // successful logs has the reference link to the payment authorisation
        PaymentGatewayLog pglAuth = [SELECT id, OrderPaymentSummaryId FROM PaymentGatewayLog WHERE ReferencedEntityId =: paId LIMIT 1];
        pglAuth.OrderPaymentSummaryId = paList[0].OrderPaymentSummaryId;
        pglListToUpdate.add(pglAuth);

        //retrieve tokenization log, link it to the order payment summary
        // successful logs has the reference link to the payment method
        PaymentGatewayLog  pglToken = [SELECT id, OrderPaymentSummaryId FROM PaymentGatewayLog WHERE ReferencedEntityId =: paList[0].paymentMethodId LIMIT 1];
        pglToken.OrderPaymentSummaryId = paList[0].OrderPaymentSummaryId;
        pglListToUpdate.add(pglToken);

        update pglListToUpdate;
    }


    @future(callout=true)
    private static void callStripeCaptureEndpoint(id inputId) {

        PaymentAuthorization pa = [SELECT id, GatewayAuthCode, OrderPaymentSummaryId, PaymentMethodId, paymentGroupId, CurrencyIsoCode FROM PaymentAuthorization WHERE Id =: inputId];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:StripeAdapter_NC/v1/payment_intents/' +  pa.gatewayAuthCode + '/capture');
        req.setBody('{}');
        req.setMethod('POST');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        Integer sc = res.getStatusCode();

        // needs a shitton of error handling
        Map<String, Object> capture = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        Map<String, Object> charges = (Map<String, Object>)capture.get('charges');
        List<Object> datas = (List<Object>) charges.get('data');
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(datas[0]));

        String receiptUrl = (String)data.get('receipt_url');

        // one day, will move to a util class;
        // start logging
        PaymentGatewayLog pgl = new PaymentGatewayLog();
        Payment payment = new Payment();

        pgl.request = req.getBody();
        pgl.response = res.getBody();
        pgl.gatewayResultCode = string.valueOf(sc) + ' ' +  HTTP_STATUS_CODE_VALUES.get(sc);

        if (sc == 200) {

            // log all information on a sucessful capture
            pgl.interactionType = 'Capture';
            pgl.interactionStatus = 'Success';
            pgl.SfResultCode = 'Success';
            pgl.ReferencedEntityId = pa.id;
            pgl.orderPaymentSummaryId = pa.OrderPaymentSummaryId;
            pgl.gatewayDate = System.now();

            // create payment record
            payment.status = 'Processed';
            payment.amount = (Integer)capture.get('amount') / 100; // need to use the from and to for stripe;
            payment.currencyIsoCode = pa.currencyIsoCode;
            payment.type = 'Capture';
            payment.paymentAuthorizationId = pa.id;
            payment.paymentMethodId = pa.PaymentMethodId;
            payment.paymentGroupId = pa.paymentGroupId;
            payment.processingMode = 'External';
            payment.date = System.now(); 
            payment.effectiveDate = System.now();
            payment.gatewayDate = System.now();
            payment.gatewayResultCode = pgl.gatewayResultCode;
            payment.orderPaymentSummaryId = pa.OrderPaymentSummaryId;
            payment.SfResultCode = 'Success';
            payment.OSF_Capture_Receipt_URL__c = receiptUrl;
            insert payment;
        }
        
        insert pgl;


    }

}
