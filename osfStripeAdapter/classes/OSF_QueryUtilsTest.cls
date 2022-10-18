@isTest
public with sharing class OSF_QueryUtilsTest {
    
    @isTest
    static void testQueryUtil() {

        Test.startTest();
        OSF_QueryUtils q = new OSF_QueryUtils(Account.SObjectType);
        
        q.getSelectClause().addFields(new Schema.SObjectField[]{Account.Name});
        q.setWhereClause('WHERE CreatedDate = TODAY');
        Test.stopTest();
        
        // tests if the SOQL built correctly
        System.assertEquals('SELECT Name FROM Account WHERE CreatedDate = TODAY', q.buildSOQL());
        
    }
    
}