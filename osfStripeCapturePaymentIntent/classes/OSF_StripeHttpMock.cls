/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Provides a mock response for the Stripe Adapter Test Class
Test Class:    OSF_StripeAdapterTest
               OSF_StripeCapturePaymentIntentTest
<Date>         <Authors Name>     <Brief Description of Change>
14-Oct-2022    Reuben Lim         Implemented mock response.
19-Oct-2022    Reuben Lim         Updated mock JSON response messages.
                                  Removed unnecessary response messages due to SF not supporting it.
                                  Added a param into the constructor to specify status code and respond accordingly with the right message
20-Oct-2022    Reuben Lim         Updated mock to include a charges response for Capturing of Payment Intents.
------------------------------------------------------------*/
@istest
global class OSF_StripeHttpMock implements HttpCalloutMock{

    private integer responseStatusCode;

    global OSF_StripeHttpMock(integer statusCode) {
        responseStatusCode = statusCode;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if (responseStatusCode == 200)  {
            if (req.getEndpoint().contains('payment_methods')) {
                res.setBody('{"id":"pm_1LuNR3KgY5eOD51na1PfmGze","object":"payment_method","billing_details":{"address":{"city":"test","country":"AU","line1":"123 test st","line2":null,"postal_code":"1234","state":"NSW"},"email":null,"name":"test","phone":null},"card":{"brand":"visa","checks":{"address_line1_check":"unchecked","address_postal_code_check":"unchecked","cvc_check":"unchecked"},"country":"US","exp_month":12,"exp_year":2024,"fingerprint":"aJk3zxvb9nZGDcRk","funding":"credit","generated_from":null,"last4":"4242","networks":{"available":["visa"],"preferred":null},"three_d_secure_usage":{"supported":true},"wallet":null},"created":1666128893,"customer":null,"livemode":false,"metadata":{},"type":"card"}');
            } else if (req.getEndpoint().contains('payment_intents') && !req.getEndpoint().contains('capture')) {
                res.setBody('{"id":"pi_3LuNR4KgY5eOD51n1TagifXY","object":"payment_intent","amount":5400,"amount_capturable":5400,"amount_details":{"tip":{}},"amount_received":0,"application":null,"application_fee_amount":null,"automatic_payment_methods":null,"canceled_at":null,"cancellation_reason":null,"capture_method":"manual","charges":{"object":"list","data":[{"id":"ch_3LuNR4KgY5eOD51n1iGDSS4i","object":"charge","amount":5400,"amount_captured":0,"amount_refunded":0,"application":null,"application_fee":null,"application_fee_amount":null,"balance_transaction":null,"billing_details":{"address":{"city":"test","country":"AU","line1":"123 test st","line2":null,"postal_code":"1234","state":"NSW"},"email":null,"name":"test","phone":null},"calculated_statement_descriptor":"Stripe","captured":false,"created":1666128895,"currency":"aud","customer":null,"description":null,"destination":null,"dispute":null,"disputed":false,"failure_balance_transaction":null,"failure_code":null,"failure_message":null,"fraud_details":{},"invoice":null,"livemode":false,"metadata":{},"on_behalf_of":null,"order":null,"outcome":{"network_status":"approved_by_network","reason":null,"risk_level":"normal","risk_score":53,"seller_message":"Payment complete.","type":"authorized"},"paid":true,"payment_intent":"pi_3LuNR4KgY5eOD51n1TagifXY","payment_method":"pm_1LuNR3KgY5eOD51na1PfmGze","payment_method_details":{"card":{"brand":"visa","checks":{"address_line1_check":"pass","address_postal_code_check":"pass","cvc_check":"pass"},"country":"US","exp_month":12,"exp_year":2024,"fingerprint":"aJk3zxvb9nZGDcRk","funding":"credit","installments":null,"last4":"4242","mandate":null,"network":"visa","three_d_secure":null,"wallet":null},"type":"card"},"receipt_email":null,"receipt_number":null,"receipt_url":"https://pay.stripe.com/receipts/payment/CAcaFwoVYWNjdF8xTFBKbVlLZ1k1ZU9ENTFuKP-3vJoGMgblmS7OTDk6LBYtU9suJ3AL1DCjIoorQ5hePFUWmtSxgp5y2PK1I3VZkNaOOQVWrm7Iso6f","refunded":false,"refunds":{"object":"list","data":[],"has_more":false,"total_count":0,"url":"/v1/charges/ch_3LuNR4KgY5eOD51n1iGDSS4i/refunds"},"review":null,"shipping":null,"source":null,"source_transfer":null,"statement_descriptor":null,"statement_descriptor_suffix":null,"status":"succeeded","transfer_data":null,"transfer_group":null}],"has_more":false,"total_count":1,"url":"/v1/charges?payment_intent=pi_3LuNR4KgY5eOD51n1TagifXY"},"client_secret":"pi_3LuNR4KgY5eOD51n1TagifXY_secret_vh5zNBgfpFHYhgP0cDFH89qn0","confirmation_method":"manual","created":1666128894,"currency":"aud","customer":null,"description":null,"invoice":null,"last_payment_error":null,"livemode":false,"metadata":{},"next_action":null,"on_behalf_of":null,"payment_method":"pm_1LuNR3KgY5eOD51na1PfmGze","payment_method_options":{"card":{"installments":null,"mandate_options":null,"network":null,"request_three_d_secure":"automatic"}},"payment_method_types":["card"],"processing":null,"receipt_email":null,"review":null,"setup_future_usage":null,"shipping":null,"source":null,"statement_descriptor":null,"statement_descriptor_suffix":null,"status":"requires_capture","transfer_data":null,"transfer_group":null}');
            } else if (req.getEndpoint().contains('payment_intents') && req.getEndpoint().contains('capture')) {
				res.setBody('{"id":"pi_3Luab4KgY5eOD51n0IBXDBsa","object":"payment_intent","amount":6200,"amount_capturable":0,"amount_details":{"tip":{}},"amount_received":6200,"application":null,"application_fee_amount":null,"automatic_payment_methods":null,"canceled_at":null,"cancellation_reason":null,"capture_method":"manual","charges":{"object":"list","data":[{"id":"ch_3Luab4KgY5eOD51n0XfSpsEK","object":"charge","amount":6200,"amount_captured":6200,"amount_refunded":0,"application":null,"application_fee":null,"application_fee_amount":null,"balance_transaction":"txn_3Luab4KgY5eOD51n0Q5T58QN","billing_details":{"address":{"city":"test","country":"AU","line1":"123 test st","line2":null,"postal_code":"1234","state":"NSW"},"email":null,"name":"test","phone":null},"calculated_statement_descriptor":"Stripe","captured":true,"created":1666179487,"currency":"aud","customer":null,"description":"Amorfa purchase","destination":null,"dispute":null,"disputed":false,"failure_balance_transaction":null,"failure_code":null,"failure_message":null,"fraud_details":{},"invoice":null,"livemode":false,"metadata":{},"on_behalf_of":null,"order":null,"outcome":{"network_status":"approved_by_network","reason":null,"risk_level":"normal","risk_score":45,"seller_message":"Payment complete.","type":"authorized"},"paid":true,"payment_intent":"pi_3Luab4KgY5eOD51n0IBXDBsa","payment_method":"pm_1Luab3KgY5eOD51nsf5kQccY","payment_method_details":{"card":{"brand":"visa","checks":{"address_line1_check":"pass","address_postal_code_check":"pass","cvc_check":"pass"},"country":"US","exp_month":12,"exp_year":2024,"fingerprint":"aJk3zxvb9nZGDcRk","funding":"credit","installments":null,"last4":"4242","mandate":null,"network":"visa","three_d_secure":null,"wallet":null},"type":"card"},"receipt_email":null,"receipt_number":null,"receipt_url":"https://pay.stripe.com/receipts/payment/CAcaFwoVYWNjdF8xTFBKbVlLZ1k1ZU9ENTFuKKfDv5oGMga51m2R_qM6LBbUs3MRbC4AqXRadrD26T4ppMrspPCOnp72uFJWlWq95pYiUDgeqUkVTLLx","refunded":false,"refunds":{"object":"list","data":[],"has_more":false,"total_count":0,"url":"/v1/charges/ch_3Luab4KgY5eOD51n0XfSpsEK/refunds"},"review":null,"shipping":null,"source":null,"source_transfer":null,"statement_descriptor":null,"statement_descriptor_suffix":null,"status":"succeeded","transfer_data":null,"transfer_group":null}],"has_more":false,"total_count":1,"url":"/v1/charges?payment_intent=pi_3Luab4KgY5eOD51n0IBXDBsa"},"client_secret":"pi_3Luab4KgY5eOD51n0IBXDBsa_secret_jaLBrMcofkarwThdXy4L5WUud","confirmation_method":"manual","created":1666179486,"currency":"aud","customer":null,"description":"Amorfa purchase","invoice":null,"last_payment_error":null,"livemode":false,"metadata":{},"next_action":null,"on_behalf_of":null,"payment_method":"pm_1Luab3KgY5eOD51nsf5kQccY","payment_method_options":{"card":{"installments":null,"mandate_options":null,"network":null,"request_three_d_secure":"automatic"}},"payment_method_types":["card"],"processing":null,"receipt_email":null,"review":null,"setup_future_usage":null,"shipping":null,"source":null,"statement_descriptor":null,"statement_descriptor_suffix":null,"status":"succeeded","transfer_data":null,"transfer_group":null}');
            } else {
                res.setBody('{}');
            }
        } else if (responseStatusCode == 400) {
            if (req.getEndpoint().contains('payment_methods')) {
                res.setBody('{"error":{"code":"parameter_missing","doc_url":"https://stripe.com/docs/error-codes/parameter-missing","message":"Missing required param: type.","param":"type","request_log_url":"https://dashboard.stripe.com/test/logs/req_5IlXspTP1Fz60Y?t=1666092392","type":"invalid_request_error"}}');
            } else if (req.getEndpoint().contains('payment_intents') && !req.getEndpoint().contains('capture')) {
                res.setBody('{"error":{"message":"Invalid boolean: true1234","param":"confirm","request_log_url":"https://dashboard.stripe.com/test/logs/req_GNsrVWerxBvN3N?t=1666092977","type":"invalid_request_error"}}');
            } else if (req.getEndpoint().contains('payment_intents') && req.getEndpoint().contains('capture')) {
				res.setBody('{"error":{"code":"resource_missing","doc_url":"https://stripe.com/docs/error-codes/resource-missing","message":"No such payment_intent: \'pi_3LuaxUKgY5eOD51n1gdBF45z123\'","param":"intent","request_log_url":"https://dashboard.stripe.com/test/logs/req_2nGB8wKBlzxaBN?t=1666180881","type":"invalid_request_error"}}');
            } else {
                res.setBody('{}');
            }
        }

        res.setStatusCode(responseStatusCode);
        return res;
    }

}