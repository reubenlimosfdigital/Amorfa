/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Retrieves the appropriate Order Delivery Methods for Checkout.
               Can be used for both B2B and D2C storefronts. Update the test class
               with the appropriate test data setup.
Test Class:    OSF_B2BDeliveryTest
<Date>         <Authors Name>     <Brief Description of Change>
22-May-2023    Reuben Lim         Implemented the base code.
30-May-2023    Ajmal Shah         Updated to handle dynamic stores.
31-May-2023    Reuben Lim         Picks up the right ODM records based on address type
                                  Added graceful error handling on a null ODM List
06-Jun-2023    Reuben Lim         Set to fixed pricing as discussed with Mirana
09-Jun-2023	   Reuben Lim	      Removed OSF identification from class name and fields
19-Jun-2023	   Reuben Lim	      Renamed classes
20-Jun-2023    Reuben Lim         Added in isRunningTest exception trigger for testing
------------------------------------------------------------*/

// This must implement the sfdc_checkout.CartShippingCharges interface
// in order to be processed by the checkout flow for the "Shipping" integration
global with sharing class OSF_Delivery implements sfdc_checkout.CartShippingCharges {
    
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // We need to get the ID of the cart delivery group in order to create the order delivery groups.
            Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId][0].Id;

            // On re-entry of the checkout flow delete all previous CartDeliveryGroupMethods for the given cartDeliveryGroupId
            delete [SELECT Id FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId];
        
            // retrieve all relevent information
            WebCart webCart = [SELECT WebStoreId, CurrencyISOCode  FROM WebCart where id =: cartId limit 1];
            CartDeliveryGroup cdg = [SELECT id, DeliverToName from CartDeliveryGroup WHERE CartId =: cartId LIMIT 1];
            
            // retrieve all Order Delivery Methods
            List<OrderDeliveryMethod> odmList = [SELECT Id, Name, OSF_Price__c FROM OrderDeliveryMethod 
                                                 WHERE OSF_Store__c =: webCart.WebstoreId AND isActive = TRUE];

            // gracefully handles the situation where no delivery methods are found
            if (odmList.size() == 0) {
                return integrationStatusFailedWithCartValidationOutputError(
                            integStatus,
                            'No delivery methods found. Please contact your Salesforce admin.',
                            jobInfo,
                            cartId
                        );
            }

            // if test scenario, then trigger a DML insert failure
            if (Test.isRunningTest() && odmList.size() == 3) {
                insert new CartDeliveryGroupMethod();
            } else if (Test.isRunningTest() && odmList.size() == 4) {
                throw new IllegalArgumentException('Testing Generic Exception error handling');
            }

            // for each possible ODM record,  create the relevent CDGM record to display to user
            for (OrderDeliveryMethod odm : odmList){
                insert new CartDeliveryGroupMethod(  CartDeliveryGroupId = cartDeliveryGroupId,
                                                    DeliveryMethodId = odm.id,
                                                    Name = odm.name,
                                                    ShippingFee = odm.OSF_Price__c == null ? 0 : odm.OSF_Price__c,
                                                    WebCartId = cartId,
                                                    CurrencyISOCode = webCart.currencyISOCode); 
            }
  
            // If everything works well, the charge is added to the cart and our integration has been successfully completed.
            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;

        // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
        // In production you probably want this to be an admin-type error. In that case, throw the exception here
        // and make sure that a notification system is in place to let the admin know that the error occurred.
        // See the readme section about error handling for details about how to create that notification.
        } catch (DmlException de) {
            // Catch any exceptions thrown when trying to insert the shipping charge to the CartItems
            Integer numErrors = de.getNumDml();
            String errorMessage = 'There were ' + numErrors + ' errors when trying to insert the charge in the CartItem: ';
            for(Integer errorIdx = 0; errorIdx < numErrors; errorIdx++) {
                errorMessage += 'Field Names = ' + de.getDmlFieldNames(errorIdx);
                errorMessage += 'Message = ' + de.getDmlMessage(errorIdx);
                errorMessage += ' , ';
            }
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                errorMessage,
                jobInfo,
                cartId
            );
        } catch(Exception e) {
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }

        private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // In order for the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user
            // Name (required): The name of this CartValidationOutput record. For example CartId:BackgroundOperationId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Shipping'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
    
}