/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Provides a mock response for the Stripe Adapter Test Class
Test Class:    N/A
<Date>         <Authors Name>     <Brief Description of Change>
14-Oct-2022    Reuben Lim         Implemented mock response.
------------------------------------------------------------*/
@istest
global class OSF_StripeAdapterMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
        System.debug(req.getEndpoint());

        // Create a fake response
        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'application/json');
        
        if (req.getEndpoint().contains('charges')) {
            res.setBody('{"amount": 10000}');

        } else if(req.getEndpoint().contains('tokens')) {
            res.setBody('{"id": "token"}');

        // mock response for creating a tokenized response
        } else if(req.getEndpoint().contains('payment_methods')) {
            res.setBody('{}');

        // mock response for auth payment
        } else if(req.getEndpoint().contains('payment_intents')) {
            res.setBody('{"charges":{"data":[{"status":"Test","amount":1000}]}}');

        // mock response for auth refund
        } else if(req.getEndpoint().contains('refunds')) {
            res.setBody('{"amount": 1000, "balance_transaction": "balance", "receipt_url": "https://www.stripe.com"}');
        }

        res.setStatusCode(200);
        return res;
    }
}