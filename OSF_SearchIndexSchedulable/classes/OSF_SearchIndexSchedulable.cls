/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Implemented a schedulable search index refresh. Does all storefronts.
               To schedule Apex, go to Setup -> Apex Classes. Click on Schedule Apex.
               Fill in the Job Name, Apex Class (this class) and times to run.
Test Class:    OSF_SearchIndexSchedulableTest
<Date>         <Authors Name>     <Brief Description of Change>
22-Nov-2022    Reuben Lim         Implemented.
------------------------------------------------------------*/

global class OSF_SearchIndexSchedulable implements Schedulable {

    global void execute(SchedulableContext SC) {

        List<WebStore> webstores = [SELECT id FROM WebStore];

        for (WebStore ws : webstores) {
            ConnectApi.CommerceSearchIndex searchIndex = ConnectApi.CommerceSearchSettings.createCommerceSearchIndex(ws.id);
        }


     }

}