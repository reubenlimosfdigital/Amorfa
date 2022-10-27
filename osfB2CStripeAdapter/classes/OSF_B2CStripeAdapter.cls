/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Implements Stripe as a Payment Provider during checkout.
               Based on the SF reference class. Currently tested with B2B2C only.
Test Class:    OSF_B2CStripeAdapterTest
<Date>         <Authors Name>     <Brief Description of Change>
14-Oct-2022    Reuben Lim         Implemented test class since SF doesn't provide one.
17-Oct-2022    Reuben Lim         Implemented a logic check to support multi-currency.
18-Oct-2022    Reuben Lim         Removed unused logic. Only Authorize and Tokenize methods are used.
27-Oct-2022    Reuben Lim         Renamed as this only works for B2B2C cases.
------------------------------------------------------------*/

global class OSF_B2CStripeAdapter implements commercepayments.PaymentGatewayAdapter {

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

    global OSF_B2CStripeAdapter() {
    }

    // the process request class method is called by the payment gateway component
    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        commercepayments.PaymentGatewayRequest paymentRequest = gatewayContext.getPaymentRequest();
        commercepayments.GatewayResponse response;

        try {
            // Tokenize is called first, Authorize.
            // Tokenize sets up the payment information like cc details
            // Authorize uses the token to hold payment
            if (requestType == commercepayments.RequestType.Tokenize) {
                response = createTokenizeResponse((commercepayments.PaymentMethodTokenizationRequest) paymentRequest);
            } else if (requestType == commercepayments.RequestType.Authorize) {
                response = createAuthResponse((commercepayments.AuthorizationRequest) paymentRequest);
            }
            return response;
        } catch (StripeValidationException e) {
             return new commercepayments.GatewayErrorResponse('400', e.getMessage());
        }
    }
    
    // this call sets up the payment method, i.e. by credit card
    public commercepayments.GatewayResponse createTokenizeResponse(commercepayments.PaymentMethodTokenizationRequest tokenizeRequest) {
        // API: https://stripe.com/docs/api/payment_methods

        commercepayments.CardPaymentMethodRequest cardPaymentMethod = tokenizeRequest.cardPaymentMethod;

        Map<String, String> params = new Map<String, String>();
        params.put('type', 'card');
        params.put('card[number]', cardPaymentMethod.cardNumber);
        params.put('card[exp_month]', String.valueOf(cardPaymentMethod.expiryMonth));
        params.put('card[exp_year]', String.valueOf(cardPaymentMethod.expiryYear));
        params.put('card[cvc]', cardPaymentMethod.cvv);
        
        // add fraud data
        if (tokenizeRequest.ipAddress != null) {
            params.put('ip', tokenizeRequest.ipAddress);
        }
        Map<String, String> additionalData = tokenizeRequest.additionalData;
        if (additionalData != null) {
            params.put('referrer', urlEncode(additionalData.get('referrer')));
            params.put('user_agent', urlEncode(additionalData.get('user_agent')));
            params.put('payment_user_agent', urlEncode(additionalData.get('payment_user_agent')));
        }

        commercepayments.AddressRequest billingAddress = tokenizeRequest.address;

        if (billingAddress != null) {
            params.put('billing_details[name]', urlEncode(cardPaymentMethod.cardHolderName));
            params.put('billing_details[address[line1]]', billingAddress.street);
            params.put('billing_details[address[city]]', billingAddress.city);
            params.put('billing_details[address[state]]', billingAddress.state);
            params.put('billing_details[address[postal_code]]', billingAddress.postalCode);
            params.put('billing_details[address[country]]', billingAddress.country);
        }

        HttpResponse response = doPost('payment_methods', params);
       
        String body = response.getBody();
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(body);
        Integer sc = response.getStatusCode();
        commercepayments.PaymentMethodTokenizationResponse tokenizeResponse = new commercepayments.PaymentMethodTokenizationResponse();

        tokenizeResponse.setGatewayDate(system.now());
        tokenizeResponse.setGatewayResultCode(String.valueOf(sc) + ' ' + HTTP_STATUS_CODE_VALUES.get(sc)); //64 max

        // testing has shown only 3 responses, a 200 OK and a 400 Bad Request and 402 Request Fail
        // any other response types have an unknown structure
        // elected to not capture any other specific information as body is always captured
        if (sc == 200) {
            tokenizeResponse.setGatewayTokenEncrypted((String) results.get('id'));
            tokenizeResponse.setSalesforceResultCodeInfo(RC_SUCCESS);
        }
        else if (sc == 400 || sc == 402) {
            Map<String, Object> error = (Map<String, Object>) results.get('error');
            tokenizeResponse.setGatewayResultCodeDescription((String) error.get('type') + ': ' + (String) error.get('code')); //1000 max
            tokenizeResponse.setGatewayMessage(((String) error.get('message')).left(255)); //255 max
            tokenizeResponse.setSalesforceResultCodeInfo(RC_DECLINE);
        } else {
            tokenizeResponse.setSalesforceResultCodeInfo(RC_DECLINE);
        }
        return tokenizeResponse;
    }

    // this calls out the Authorize
    public commercepayments.GatewayResponse createAuthResponse(commercepayments.AuthorizationRequest authRequest) {
        // API: https://stripe.com/docs/api/payment_intents
        //      https://stripe.com/docs/api/charges/create
        commercepayments.AuthApiPaymentMethodRequest paymentMethod = authRequest.paymentMethod;

        // get the cardPaymentMethod object with the token
        OSF_QueryUtils q = new OSF_QueryUtils(CardPaymentMethod.SObjectType);
        q.getSelectClause().addField('GatewayToken', false);
        q.getSelectClause().addField('GatewayTokenEncrypted', false);
        q.setWhereClause(' WHERE Id =' + '\'' + paymentMethod.id + '\'');
        
        // if we are running tests, specify a new CPM record else retrieve from object
        CardPaymentMethod cardPaymentMethod = Test.isRunningTest() ? new CardPaymentMethod(GatewayToken='pm_') : (CardPaymentMethod)Database.query(q.buildSOQL())[0];

        String token = cardPaymentMethod.GatewayTokenEncrypted;
        if (String.isBlank(token)) {
            token = cardPaymentMethod.GatewayToken;
        }
        String currencyIsoCode = authRequest.currencyIsoCode;
        String amount = toStripeCurrencyUnits(currencyIsoCode, authRequest.amount);

        Map<String, String> params = new Map<String, String>();
        params.put('amount', amount);
        params.put('currency', currencyIsoCode);

        commercepayments.AuthorizationResponse authResponse = new commercepayments.AuthorizationResponse();
        authResponse.setGatewayDate(system.now());

        // API: https://stripe.com/docs/api/payment_intents
        params.put('amount', String.valueOf(amount));
        params.put('currency', currencyIsoCode);
        params.put('payment_method', urlEncode(token));
        params.put('confirm', 'true'); //  create & authorize
        params.put('confirmation_method', 'manual'); // e.g. 3DS
        params.put('capture_method', 'manual');
        //params.put('receipt_email', UserInfo.getUserEmail()); // for future use, need to identify how to retrieve email
        //extra stuff
        params.put('description','Amorfa purchase');
        
        HttpResponse response = doPost('payment_intents', params);
        String body = response.getBody();
        Map<String, Object> intent = (Map<String, Object>) JSON.deserializeUntyped(body);

        String gatewayAuthCode = (String) intent.get('id');

        Integer sc = response.getStatusCode();
        // map: https://stripe.com/docs/api/errors
        // to: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_commercepayments_SalesforceResultCode.htm

        authResponse.setGatewayDate(system.now());
        authResponse.setGatewayResultCode(String.valueOf(sc) + ' ' + HTTP_STATUS_CODE_VALUES.get(sc)); //64 max
        
        //have seen only 200 success and 400 and 402
        
        if (sc == 200) {
            authResponse.setGatewayAuthCode(gatewayAuthCode);
            authResponse.setAmount(fromStripeCurrencyUnits((String) intent.get('currency'), (Long) intent.get('amount')));
            authResponse.setSalesforceResultCodeInfo(RC_SUCCESS);
        } else if (sc == 400 || sc == 402) {
            Map<String, Object> error = (Map<String, Object>) intent.get('error');
            String declineCode = (String)error.get('decline_code');
            authResponse.setGatewayResultCodeDescription((String) error.get('type') + ': ' + (String) error.get('code') + 
                                                         (declineCode == null ? '' : ': ' + declineCode)); //1000 
            authResponse.setGatewayMessage(((String) error.get('message')).left(255)); //255 max
            authResponse.setSalesforceResultCodeInfo(RC_DECLINE);
        } else {
            authResponse.setSalesforceResultCodeInfo(RC_DECLINE);
        }

        //  Make sure the token from the response gets encrypted in the payment gateway log.
        commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
        paymentMethodTokenizationResponse.setGatewayTokenEncrypted(token);
        authResponse.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);

        return authResponse;
    }

    private static HttpResponse doPost(String path, Map<String, String> params) {
        commercepayments.PaymentsHttp http = new commercepayments.PaymentsHttp();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('/v1/' + path);

        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(urlEncodedParams(params));

        return http.send(request);
    }

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

    private static Double fromStripeCurrencyUnits(String currencyIsoCode, Long amount) {

        if (ZERO_DECIMAL_CURRENCY.contains(currencyIsoCode.toLowercase())) {
            return (Double)amount;
        }

        return ((Double)amount / 100.0);
    }

    private static commercepayments.SalesforceResultCodeInfo toCodeInfo(commercepayments.SalesforceResultCode code) {
        return new commercepayments.SalesforceResultCodeInfo(code);
    }
}