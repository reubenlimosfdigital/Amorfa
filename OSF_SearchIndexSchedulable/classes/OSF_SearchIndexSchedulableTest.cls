/*------------------------------------------------------------
Author:        Reuben Lim
Company:       OSF Digital ANZ
Description:   Test class for OSF_SearchIndexSchedulable
Test Class:    
<Date>         <Authors Name>     <Brief Description of Change>
22-Nov-2022    Reuben Lim         Implemented.
------------------------------------------------------------*/
@isTest(SeeAllData=true)
private class OSF_SearchIndexSchedulableTest {
    
    @isTest
    static void testSchedulable() {
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Math.Mod(Datetime.now().minute() + 10, 60)); 
        String ss = String.valueOf(Datetime.now().second());
        
        String cronExp = ss + ' ' + min + ' ' + hour + ' ? * *';
        
        Test.startTest();
        String jobId = System.schedule('ScheduledApexTest', cronExp, new OSF_SearchIndexSchedulable());
        Test.stopTest();
    }
}