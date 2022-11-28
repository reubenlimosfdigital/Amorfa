/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Retrieves the appropriate data and pallet calcs to determine the current pallet utiliziation.
               Shamelessly forked from the global team's work.
Test Class:    OSF_B2BPalletUtilizationControllerTest
<Date>         <Authors Name>     <Brief Description of Change>
28-Nov-2022    Reuben Lim         Implemented
------------------------------------------------------------*/

@isTest(SeeAllData=true)
public with sharing class OSF_B2BPalletUtilizationControllerTest {

    // Connect API requires SellAllData=true, and can't use it for @TestSetup
    private static void makeData() {
             
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();

        //generate test account
        Account a = new Account(name = 'B2BPalletUtilizationControllerAccount', recordTypeId=accountRecordTypeId, currencyIsoCode='NZD');
        insert a;

        //create buyer account and link to test account
        BuyerAccount ba = new BuyerAccount(Name = 'Test Account', BuyerId=a.id, BuyerStatus='Active', isActive=true, currencyIsoCode='NZD');
        insert ba;
        
        //create buyer group
        BuyerGroup bg = new BuyerGroup(Name='Test Buyer Group');        
        insert bg;
        
        //get the webstore id
        WebStore ws = [SELECT id from WebStore WHERE type='B2B' LIMIT 1];
        
        // create product and pricebook and pricebook entry
        Product2 p = new Product2(name='Test Product', StockKeepingUnit='TEST', ProductCode='TEST', isActive=true, currencyIsoCode='NZD');
        insert p;
        
        PriceBook2 pb = new PriceBook2(name='Test Pricebook', isActive=true);
        insert pb;
        
        insert new PriceBookEntry(Pricebook2Id=Test.getStandardPricebookId(), Product2Id=p.id, currencyIsoCode='NZD', unitPrice=10, isActive=true);
        
        PriceBookEntry pbe = new PriceBookEntry(Pricebook2Id=pb.id, Product2Id=p.id, currencyIsoCode='NZD', unitPrice=10, isActive=true);
        insert pbe;
        
        // retrieve store catalog
        WebStoreCatalog wsc = [SELECT ProductCatalogId From WebStoreCatalog WHERE SalesStoreId =: ws.id];
                
        // create category and link to store catalog, then link to product
        ProductCategory pCategory = new ProductCategory(name='Test Category', catalogId=wsc.ProductCatalogId);
        insert pCategory;
        
        ProductCategoryProduct pcp = new ProductCategoryProduct(ProductId=p.id, ProductCategoryId=pCategory.id);
        insert pcp;
        
        // link entitlement policy to product and buyer group
        CommerceEntitlementPolicy cePolicy = new CommerceEntitlementPolicy(name='Test Entitlement', isActive=true,canViewPrice=true, canViewProduct=true);
        insert cePolicy;
        
        CommerceEntitlementProduct ceProduct = new CommerceEntitlementProduct(policyId=cePolicy.id, ProductId=p.id);
        insert ceProduct;
        
        CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup(policyId=cePolicy.id, BuyerGroupId=bg.id);
        insert cebg;
        
        // link the buyer group to everything
        // store, buyer group, entitlement policy, pricebook
        WebStoreBuyerGroup wsbg = new WebStoreBuyerGroup(WebStoreId=ws.id, BuyerGroupId=bg.id);
        insert wsbg;

        BuyerGroupMember bgm = new BuyerGroupMember(BuyerId=a.id, BuyerGroupId=bg.id);
        insert bgm;
        
        BuyerGroupPricebook bgpb = new BuyerGroupPricebook(BuyerGroupId=bg.id, Pricebook2id=pb.id, isActive=true, priority=1);
        insert bgpb;
        
        //this is the reason we need SeeAllData=true. You can't generate the cart without it
        ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
        cartInput.effectiveAccountId = a.id;
        cartInput.name = 'B2BPalletUtilizationControllerCart';
        ConnectApi.CartSummary cs = ConnectApi.CommerceCart.createCart(ws.id, cartInput);
        
        ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
        cartItemInput.productId = p.id;
        cartItemInput.quantity = '30';
        cartItemInput.type =  ConnectApi.CartItemType.Product;
        ConnectApi.CommerceCart.addItemToCart(ws.id, a.id, String.valueOf(cs.cartId), cartItemInput);
        
    }

    @isTest
    public static void testPalletUtilizationCalculations(){
        makeData();
        
        Test.startTest();
		ConnectApi.CommunityPage commPage = ConnectApi.Communities.getCommunities();
        Id communityId = commPage.communities[0].Id;
        
        Account effectiveAccount = [SELECT id FROM Account WHERE name='B2BPalletUtilizationControllerAccount' AND createdDate = TODAY LIMIT 1];
        WebCart cart = [SELECT id FROM WebCart WHERE name='B2BPalletUtilizationControllerCart' AND createdDate = TODAY LIMIT 1];
        
        Object response = OSF_B2BPalletUtilizationController.getCartItems(communityId, effectiveAccount.id, cart.id);
		system.debug(response);
        
        //this part should test out the pallet calcs for each and every implementation to make sure its working right.
		//00:20:26:661 USER_DEBUG [103]|DEBUG|CartItemResponse:[fullPalletCount=1, lastPalletUtilisationPercent=0, totalCartVolume=3.000000000]        
        
        
        Test.stopTest();
        
        
    }
}