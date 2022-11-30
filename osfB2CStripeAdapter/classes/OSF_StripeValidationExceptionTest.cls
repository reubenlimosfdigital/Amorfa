@isTest
public with sharing class OSF_StripeValidationExceptionTest {
    
    @isTest
    static void testException() {
        Test.startTest();
        OSF_StripeValidationException stripeException = new OSF_StripeValidationException();
        Test.stopTest();
    }
}
