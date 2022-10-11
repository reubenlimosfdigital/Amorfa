//Method to generate Order Summary must have SeeAllData = true

@isTest(SeeAllData=true)
public class OSF_OrderConfirmationControllerTest {

    @isTest
    public static void testSetOrderSummaryIdAsNull() {
        OSF_OrderConfirmationController occ = new OSF_OrderConfirmationController();
        occ.orderSummaryId = null;
        
        Test.startTest();
        system.assertEquals(occ.getOrderSummary(), null, 'Setting a null order summary id should result in a null return on get order summary record');
        Test.stopTest();
    }
    
    @isTest
    public static void testSetOrderSummaryIdAsValidRecord() {
        OSF_OrderConfirmationController occ = new OSF_OrderConfirmationController();
        occ.orderSummaryId = generateOrderSummaryTestRecord();
        
        Test.startTest();
        system.assertNotEquals(occ.getOrderSummary(), null, 'Setting a valid order summary id should result in an order summary record returned');
        Test.stopTest();
    }
    
    // generates a test Order Summary and returns the record id
    @TestVisible
    private static id generateOrderSummaryTestRecord() {
        
        //generate test account
        Account a = new Account(name = 'Test Account');
        insert a;
        
        //generate test contact
        Contact c = new Contact(accountId = a.id, firstName = 'Test', lastName = 'Contact');
        insert c;
        
        //generate product
        Product2 p = new Product2(name = 'Test Product', isActive = true, productCode = 'TEST');
        insert p;
        
        //generate new pricebook
        Pricebook2 pb = new Pricebook2(name = 'Test Pricebook', isActive = true);
        insert pb;
        
        //add product to standard price book.
		insert new PriceBookEntry(pricebook2Id = Test.getStandardPricebookId(), product2Id = p.id, isActive = true, unitPrice = 100);
        
        //add product to new pricebook
		PricebookEntry pbe = new PriceBookEntry(Pricebook2Id = pb.id, product2Id = p.id, isActive = true, unitPrice = 100);
		insert pbe;
        
        //generate order
        Order o = new Order(accountId = a.id, effectiveDate = Date.today(), status = 'Draft', pricebook2Id = pb.id);
        insert o;
        
        //generate order delivery group method
        OrderDeliveryMethod odm = new OrderDeliveryMethod(Name = 'Test Order Delivery Method', isActive = true);
        insert odm;
        
        // generate order delivery group
        OrderDeliveryGroup odg = new OrderDeliveryGroup(orderId = o.id, OrderDeliveryMethodId = odm.id, DeliverToName = 'Test Deliver To');
        insert odg;
                
        //add order items
        OrderItem oi = new OrderItem();
        oi.OrderId = o.id;
        oi.Product2Id = p.Id;
        oi.PricebookEntryId = pbe.id;
        oi.OrderDeliveryGroupId = odg.id;
        oi.Quantity = 10;
        oi.UnitPrice = 100;
        oi.TotalLineAmount = 1000;
        insert oi;
        
        //activate the order prior to generating the order summary
        o.status = 'Activated';
        update o;
        
        //generate order summary
        //this is the reason we need SeeAllData=true. You can't generate the order summary without it
        ConnectApi.OrderSummaryInputRepresentation osInput = new ConnectApi.OrderSummaryInputRepresentation();
        
        osInput.orderId = o.id;
        osInput.orderLifeCycleType = 'UNMANAGED';
        
        ConnectApi.OrderSummaryOutputRepresentation osOutput = ConnectApi.OrderSummaryCreation.createOrderSummary(osInput);
        
        return osOutput.orderSummaryId;

    }
    
}