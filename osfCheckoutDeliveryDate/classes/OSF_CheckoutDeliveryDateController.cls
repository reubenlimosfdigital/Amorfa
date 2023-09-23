/**********************************************************************************************
 * @description Controller class for the Checkout Delivery Date component
 *********************************************************************************************/
public class OSF_CheckoutDeliveryDateController {
    /**********************************************************************************************
     * @description  Updates the requested delivery date and time for a given cart delivery group
     * @param        recordId The Id of the cart delivery group to update
     * @param        requestedDeliveryDate The requested delivery date
     * @param        requestedDeliveryTime The requested delivery time
     * @param        isTimePickerDisable Boolean value to indicate if the time picker is disabled
     ***********************************************************************************************/
    @AuraEnabled
    public static void updateCartDeliveryGroup(
        String recordId,
        String requestedDeliveryDate,
        String requestedDeliveryTime,
        Boolean isTimePickerDisable
    ) {
        DateTime dt;
        if (!isTimePickerDisable) {
            dt = Date.valueOf(requestedDeliveryDate);
        } else {
            Time t = parseTime(requestedDeliveryTime);
            dt = createDateTime(requestedDeliveryDate, t);
        }
        updateCartDelivery(recordId, dt);
    }

    /**********************************************************************************************
     * @description Parses the requested delivery time string and returns a Time object
     * @param requestedDeliveryTime The requested delivery time string in the format HH:MM AM/PM
     * @return Time A Time object representing the requested delivery time
     *********************************************************************************************/
    private static Time parseTime(String requestedDeliveryTime) {
        String[] timeParts = requestedDeliveryTime.split(':');
        String hour = timeParts[0].trim();
        String minute = timeParts[1].split(' ')[0].trim();
        String meridian = timeParts[1].split(' ')[1].trim();
        String formattedTime = hour + ':' + minute + ':00 ' + meridian;

        String regex = '(\\d{1,2}):(\\d{1,2}):(\\d{1,2}) ([PA]M)';
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(formattedTime);

        if (m.matches()) {
            Integer hours = Integer.valueOf(m.group(1));
            Integer minutes = Integer.valueOf(m.group(2));
            Integer seconds = Integer.valueOf(m.group(3));
            Integer pmShift = m.group(4) == 'PM' ? 12 : 0;

            return Time.newInstance(hours + pmShift, minutes, seconds, 0);
        }

        return null;
    }

    /**********************************************************************************************
     * @description  : creates a DateTime object from a given date string and Time object
     * @param        : String requestedDeliveryDate - the date string in the format YYYY-MM-DD
     * @param        : Time t - the Time object
     * @return       : DateTime - the DateTime object created from the given parameters
     ***********************************************************************************************/
    private static DateTime createDateTime(String requestedDeliveryDate, Time t) {
        String[] dateParts = requestedDeliveryDate.split('-');
        Integer year = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer day = Integer.valueOf(dateParts[2]);

        DateTime dateTimeIns = DateTime.newInstance(year, month, day, t.hour(), t.minute(), t.second());

        Date gmtDate = dateTimeIns.dateGmt();
        Time gmtTime = dateTimeIns.timeGmt();

        return DateTime.newInstanceGmt(gmtDate, gmtTime);
    }

    /**********************************************************************************************
     * @description Updates the Desired Delivery Date of a Cart Delivery Group record
     * @param  recordId The Id of the Cart Delivery Group record to be updated
     * @param  dt The desired delivery date to be set for the Cart Delivery Group record
     *********************************************************************************************/
    private static void updateCartDelivery(String recordId, DateTime dt) {
        CartDeliveryGroup cartDeliveryGroupRec = new CartDeliveryGroup(Id = recordId, DesiredDeliveryDate = dt);
        update cartDeliveryGroupRec;
    }

    /**********************************************************************************************
     * @description  : Returns the CartDeliveryGroup as a JSON string
     * @param        : String cartId - The Id of the cart
     * @return       : String - The CartDeliveryGroup as a JSON string
     ***********************************************************************************************/
    @AuraEnabled
    public static String getCartDeliveryGroup(String cartId) {
        CartDeliveryGroup deliveryGroup = [
            SELECT Id, DesiredDeliveryDate
            FROM CartDeliveryGroup
            WHERE CartId = :cartId
            LIMIT 1
        ];

        if (deliveryGroup == null) {
            return null;
        }

        // Format the DesiredDeliveryDate
        String formattedDate = deliveryGroup.DesiredDeliveryDate != null
            ? deliveryGroup.DesiredDeliveryDate.format('hh:mm a')
            : '';

        // Create a JSON object
        Map<String, Object> jsonMap = new Map<String, Object>{
            'Id' => deliveryGroup.Id,
            'DesiredDeliveryTime' => formattedDate,
            'DesiredDeliveryDate' => deliveryGroup.DesiredDeliveryDate
        };

        // Convert the JSON object to a string
        return JSON.serialize(jsonMap);
    }
}