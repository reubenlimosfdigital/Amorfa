/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Retrieves the appropriate data and pallet calcs to determine the current pallet utiliziation.
               Shamelessly forked from the global team's work.
Test Class:    OSF_B2BShippingUnitUtilizationTest
<Date>         <Authors Name>     <Brief Description of Change>
28-Nov-2022    Reuben Lim         Forked from the global team. Updated to fix error where there is no items in cart.
                                  Removed code that converted the pallet calcs into string then looks for a substring with a
                                  dot. Made it better.
01-Dec-2022    Reuben Lim         Generized component from Pallet specfic into a Shipping Unit component
------------------------------------------------------------*/

public with sharing class OSF_B2BShippingUnitUtilization {
    public class CartItemResponse{
        @AuraEnabled public Integer lastShippingUnitUtilisationPercent;
        @AuraEnabled public Integer fullShippingUnitCount;
        @AuraEnabled public Decimal totalCartVolume;
    }

    public class ShippingUnitUtilisation {
        final String WIDTH_FIELD = 'Width__c';
        final String HEIGHT_FIELD = 'Height__c';
        final STRING DEPTH_FIELD = 'Depth__c'; 
        final Decimal SHIPPING_UNIT_VOLUME = 3.00;
        final Decimal SAFETY_FACTOR = 1.00;
        final Decimal AVERAGE_CARTON_WIDTH = 1000;
        final Decimal AVERAGE_CARTON_HEIGHT = 1000;
        final Decimal AVERAGE_CARTON_DEPTH = 100;
        ConnectApi.CartItemCollection cartItems;
        Decimal shippingUnitCount;
        Decimal cartVolume;
        
        public ShippingUnitUtilisation(ConnectApi.CartItemCollection cartItems){
            this.cartItems = cartItems;
            calculateShippingUnitCount();
        }

        public void calculateShippingUnitCount(){
            
            this.ShippingUnitCount = 0;
            Decimal cartVolume = 0;
            for(ConnectApi.CartItemResult cartItemResult : cartItems.cartItems){
                ConnectApi.AbstractCartItem cartItem = cartItemResult.cartItem;
                Map <String,String> productFields = cartItem.productDetails.fields;
                decimal widthValue = 0;
                decimal heightValue = 0;
                decimal depthValue = 0;
                try {
                    widthValue = Decimal.valueOf(productFields.get(WIDTH_FIELD));
                    heightValue = Decimal.valueOf(productFields.get(HEIGHT_FIELD));
                    depthValue = Decimal.valueOf(productFields.get(DEPTH_FIELD));
                }
                catch(Exception e) {
                    /**
                     * Use avarage carton in case of missing data
                     */
                    widthValue = this.AVERAGE_CARTON_WIDTH;
                    heightValue = this.AVERAGE_CARTON_HEIGHT;
                    depthValue = this.AVERAGE_CARTON_DEPTH;
                }
                decimal cartonVolume = widthValue * heightValue * depthValue;
                //convert cartonVolume from cubic mm to cubic m
                decimal cartonVolumeInMeter = cartonVolume*0.000000001;
                // calculate cart item volume (carton volume * quantity)
                String cartItemQuantity = cartItem.quantity;
                decimal cartItemQuantityValue = Decimal.valueOf(cartItemQuantity);
                decimal cartItemVolume = cartonVolumeInMeter * cartItemQuantityValue;
                //add to cart volume
                cartVolume += cartItemVolume;
            }
            this.ShippingUnitCount = cartVolume * SAFETY_FACTOR / SHIPPING_UNIT_VOLUME;
            this.cartVolume = cartVolume;
        }

        public Decimal getTotalCartVolume() {
            return cartVolume;
        }

        public Integer getFullShippingUnitCount() {
           return ShippingUnitCount.intValue();
        }

        public Integer getLastShippingUnitUtilisationPercent() {
            return Integer.valueOf((shippingUnitCount - shippingUnitCount.intValue())*100);
         }
    }

    @AuraEnabled
    public static Object getCartItems(String communityId, String effectiveAccountId, String activeCartOrId) {   
        final String WIDTH_FIELD = 'Width__c';
        final String HEIGHT_FIELD = 'Height__c';
        final STRING DEPTH_FIELD = 'Depth__c'; 

        String webstoreId = resolveCommunityIdToWebstoreId(communityId);
        String productFields = WIDTH_FIELD+','+HEIGHT_FIELD+','+DEPTH_FIELD;
        ConnectApi.CartItemCollection cartItems = ConnectApi.CommerceCart.getCartItems(webstoreId, effectiveAccountId, activeCartOrId, productFields,null,null,null);
        
        ShippingUnitUtilisation shippingUnitUtilisation = new ShippingUnitUtilisation(cartItems);
        CartItemResponse response = new CartItemResponse();
        response.lastShippingUnitUtilisationPercent = shippingUnitUtilisation.getLastShippingUnitUtilisationPercent();
        response.fullShippingUnitCount = shippingUnitUtilisation.getFullShippingUnitCount();
        response.totalCartVolume = shippingUnitUtilisation.getTotalCartVolume();
    
        return response;
    }

    /**
   * @description Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
   * @param  communityId The Id of the community from which the call originated
   * @return webStoreId The webStoreId corresponding to the community Id.
   * @example
   * String webStoreId = B2BUtil.resolveCommunityIdToWebstoreId('0DB2D0000004Xz7');
   */
    public static String resolveCommunityIdToWebstoreId(String communityId) {
        return String.valueOf([SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId LIMIT 1].WebStoreId);
    }
}