public with sharing class OSF_CheckoutDeliveryDateController {
    @AuraEnabled
    public static void updateCartDeliveryGroup(
        String recordId,
        String requestedDeliveryDate,
        String requestedDeliveryTime
    ) {
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

            Time t = Time.newInstance(hours + PmShift, minutes, seconds, 0);

            DateTime dt = DateTime.newInstance(2023, 9, 1, t.hour(), t.minute(), t.second());
            Date gmtDate = dt.dateGmt();
            Time gmtTime = dt.timeGmt();
            DateTime gmtTime1 = DateTime.newInstanceGmt(gmtDate, gmtTime);

            // Update the CartDeliveryGroup record
            // with the new DesiredDeliveryDate
            CartDeliveryGroup cartDeliveryGroupRec = new CartDeliveryGroup(
                Id = recordId,
                DesiredDeliveryDate = gmtTime1
            );
            update cartDeliveryGroupRec;
        }
    }

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