public class OSF_OrderConfirmationController {
    
    public Id orderSummaryId {get; set;}
    public String sydneyDateTime {get; set;}
    
    // retrieves the order summary information
    public OrderSummary getOrderSummary() {
        if (String.isNotBlank(orderSummaryId)) {
            OrderSummary os = [SELECT 
                              // account details
                              Account.Name,
                              
                              // person who created the order (might be an internal Marinucci person)
                              Owner.FirstName,
                              Owner.LastName,
                              Owner.Phone,
                              OwnerId,
                              
                              // order header details
                              OriginalOrder.OrderNumber,
                              OrderedDate,
                              Status,
                              
                              // billing details
                              BillingStreet,
                              BillingCity,
                              BillingState,
                              BillingPostalCode,
                              BillingCountry,
                              BillingPhoneNumber,
                              
                              // order totals
                              TotalAdjustedProductAmount, //subtotal before tax
                              TotalAdjustedDeliveryAmount, //shipping before tax
                              TotalAdjDeliveryAmtWithTax, //shipping after tax
                              TotalTaxAmount, //subtotal tax (subtotal + shipping tax )
                              GrandTotalAmount,
                              
                              // Order Item Summary Records
                              (SELECT
                               LineNumber,
                               ProductCode,
                               Name,
                               Product2.Name, 
                               Quantity,
                               UnitPrice,
                               TotalPrice,
                               TotalLineAmountWithTax
                               FROM OrderItemSummaries
                               WHERE Type = 'Order Product'
                               ORDER BY LineNumber ASC),
                              
                              // Order Delivery Group Summary
                              (SELECT
                               DeliverToName,
                               DeliverToStreet,
                               DeliverToCity,
                               DeliverToState,
                               DeliverToPostalCode,
                               DeliverToCountry,
                               DesiredDeliveryDate
                               FROM OrderDeliveryGroupSummaries LIMIT 1)
                               
                              FROM OrderSummary WHERE Id =: orderSummaryId LIMIT 1];
            
            sydneyDateTime = formatDateToSydneyDate(os.OrderedDate, os.OwnerId);
            return os;
        }
        else {
            return null;
        }
    }
    
    // Receives the ordered date and the owner of the order summary record
    // Outputs the ordere date in a nice format, based on the owner's locale
    public String formatDateToSydneyDate(DateTime dt, Id oi) {
      
        User userRecord = [SELECT TimeZoneSidKey FROM User WHERE id =: oi LIMIT 1];
        
        return dt <> null ? dt.format('EEE dd MMMMM yyyy HH:mm z', userRecord.TimeZoneSidKey): null;
    }
}