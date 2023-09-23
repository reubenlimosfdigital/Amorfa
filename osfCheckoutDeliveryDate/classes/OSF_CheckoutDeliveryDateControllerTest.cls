@IsTest
public class OSF_CheckoutDeliveryDateControllerTest {
    @testSetup
    static void setup() {
        Account acct = new Account(
            name = 'Test OSF Commerce Account'
        );
        insert acct;

        WebStore testWebStore = new WebStore(
            Name = 'TestWebStore',
            SupportedLanguages = 'en_US',
            DefaultLanguage = 'en_US',
            type = 'B2B'
        );
        insert testWebStore;

        WebCart cart = new WebCart(Name = 'Cart FIS', WebStoreId = testWebStore.Id, AccountId = acct.Id);
        insert cart;

        List<OrderDeliveryMethod> odmList = new List<OrderDeliveryMethod>();
        odmList.add(
            new OrderDeliveryMethod(
                Name = 'ODM valid Not FIS',
                isActive = true,
                Carrier = 'Hare Carriers'
            )
        );
        odmList.add(
            new OrderDeliveryMethod(
                Name = 'ODM not valid',
                isActive = false,
                Carrier = 'Hare Carriers'
            )
        );
        insert odmList;

        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            CartId = cart.Id,
            Name = 'Default Delivery 1',
            DesiredDeliveryDate = System.now()
        );
        insert cartDeliveryGroup;

        CartItem cartItem = new CartItem(
            CartId = cart.Id,
            Sku = 'SKU_Test1',
            SalesPrice = 10.00,
            Quantity = 3.0,
            Type = 'Product',
            Name = 'TestProduct',
            CartDeliveryGroupId = cartDeliveryGroup.Id
        );
        insert cartItem;
    }

    @isTest
    static void testUpdateCartDeliveryGroup() {
        WebCart webCart = [SELECT Id, WebStoreId FROM WebCart WHERE Name = 'Cart FIS' LIMIT 1];
        String result = OSF_CheckoutDeliveryDateController.getCartDeliveryGroup(webCart.Id);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(result);

        // Test case 1: Valid time in AM
        String recordId1 = (String) m.get('Id');
        String requestedDeliveryDate1 = '2023-09-01';
        String requestedDeliveryTime1 = '10:30 AM';
        Test.startTest();
        OSF_CheckoutDeliveryDateController.updateCartDeliveryGroup(
            recordId1,
            requestedDeliveryDate1,
            requestedDeliveryTime1,
            true
        );
        Test.stopTest();
        System.assert(
            [SELECT Id FROM CartDeliveryGroup WHERE Id = :recordId1 AND DesiredDeliveryDate != NULL LIMIT 1] != null,
            'Passed!'
        );
    }

    @isTest
    static void testGetCartDeliveryGroupPositve() {
        WebCart webCart = [SELECT Id, WebStoreId FROM WebCart WHERE Name = 'Cart FIS' LIMIT 1];

        // Test case 1: Delivery group exists
        Test.startTest();
        String result = OSF_CheckoutDeliveryDateController.getCartDeliveryGroup(webCart.Id);
        Test.stopTest();
        System.assert(result != '', 'Passed!');
    }
}