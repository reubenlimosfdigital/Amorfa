/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Calculates tax on all Cart Item records on the Cart.
               Can be used for both B2B and D2C storefronts. The calculation to work out
               tax varies between B2B (Net) vs D2C (Gross). Update the calculateTax
               method with tax calculations
Test Class:    OSF_TaxTest
<Date>         <Authors Name>     <Brief Description of Change>
14-Oct-2022    Reuben Lim         Original implementation.
30-May-2023    Ajmal Shah         Updated tax to use the TotalPriceAfterAllAdjustments field.
06-Jun-2023    Reuben Lim         Removed unnecessary multi currency checks
                                  Added tax calculation logic for shipping methods
20-Jun-2023    Reuben Lim         Updated to make work for B2B and D2C scenarios
------------------------------------------------------------*/

global class OSF_Tax implements sfdc_checkout.CartTaxCalculations {
    
    // country tax codes
    private static final Map<String, Decimal> countryTaxList = New Map<String, Decimal>{'AUD'=>0.1, 'NZD'=> 0.15};
    
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            
            // delete all previous tax calcs
            delete [SELECT Id FROM CartTax WHERE CartId =: cartId];
            
            // gracefully handles the situation where no delivery methods are found
            List<CartItem> cartItemList = [SELECT id, TotalPriceAfterAllAdjustments, TotalLineGrossAmount, currencyISOCode, Type FROM CartItem WHERE CartId = :cartId];
            if (cartItemList.size() == 0) {
                return integrationStatusFailedWithCartValidationOutputError(
                            integStatus,
                            'No items in cart to calculate tax for.',
                            jobInfo,
                            cartId
                        );
            }

            WebCart cart = [SELECT Id, Name, WebstoreId, Webstore.Type FROM WebCart WHERE id =: cartId LIMIT 1];
            
            // calculating tax
            List<CartTax> cartTaxestoInsert = new List<CartTax>();
            for (CartItem cartItem : cartItemList) {
                
                CartTax tax = New CartTax();
                Decimal priceAfterAdjustments = cartItem.TotalPriceAfterAllAdjustments == null ? 0 : cartItem.TotalPriceAfterAllAdjustments;

                tax.cartItemId = cartItem.id;
                tax.taxCalculationDate = Date.today();
                tax.name = 'Goods and Services Tax (GST)';
                tax.taxType = 'Actual';
                tax.taxRate = countryTaxList.get(cartItem.currencyIsoCode);
                tax.currencyIsoCode = cartItem.currencyIsoCode;
                
                // depending on product or shipping fee, SF puts the charge into different fields
                if (cartItem.Type == 'Product') {
                    tax.amount = calculateTax(cartItem.currencyIsoCode, priceAfterAdjustments, cart.Webstore.Type);
                } else if (cartItem.Type == 'Charge') {
                    tax.amount = calculateTax(cartItem.currencyIsoCode, cartItem.TotalLineGrossAmount, cart.Webstore.Type);
                }
                
                cartTaxesToInsert.add(tax);
            }

            insert cartTaxesToInsert;

            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;

        } catch(Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
            // In production you probably want this to be an admin-type error. In that case, throw the exception here
            // and make sure that a notification system is in place to let the admin know that the error occurred.
            // See the readme section about error handling for details about how to create that notification.
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
            // For the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user (maximum 255 characters)
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
                Type = 'Taxes'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
    
    // calculates tax based on currency and store type
    // edit this function to make it work for other implementations
    private decimal calculateTax(String currencyIsoCode, Decimal amount, String storeType) {

        Decimal tax = 0.00;
        
        if (storeType == 'B2B') {
            if (currencyIsoCode == 'NZD') {
                tax = amount * 15/100;  //15% tax applied
            } else if (currencyIsoCode == 'AUD') {
                tax = amount * 10/100;  //10% tax applied
            } 
        } else if (storeType == 'B2C') {
            if (currencyIsoCode == 'NZD') {
                tax = amount * 3 / 23; //remove 15% tax
            } else if (currencyIsoCode == 'AUD') {
                tax =  amount / 11; //remove 10% tax
            }
        } 
        
        return tax;
    }

    
}