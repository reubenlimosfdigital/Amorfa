/**********************************************************************************************
* @Author:        Isaac Sedcole
* @Company:       OSF Digital ANZ
* @Description:   Test Class
* <Date>          <Authors Name>     <Brief Description of Change>
* 06-Dec-2023     Isaac Sedcole      Initial Implementation
***********************************************************************************************/
@isTest
private with sharing class OSF_TimezonePicklist_Test {
    /**********************************************************************************************
    * @description Tests the getDefaultValue() method
    *********************************************************************************************/
    @IsTest
    private static void testGetDefaultValue(){
        OSF_TimezonePicklist instance = new OSF_TimezonePicklist();

        // Capture the debug output using a log statement
        Test.startTest();
        VisualEditor.DataRow defaultValue = instance.getDefaultValue();
        Test.stopTest();

        // Assert the expected and actual values
        Assert.areEqual('Antarctica/McMurdo', defaultValue.getLabel(), 'The default value should be Antarctica/McMurdo');
    }

    /**********************************************************************************************
    * @description Test method to test getValues() method
    *********************************************************************************************/
    @IsTest
    private static void testGetValues(){
        OSF_TimezonePicklist instance = new OSF_TimezonePicklist();

        // Capture the debug output using a log statement
        Test.startTest();
        VisualEditor.DynamicPickListRows actualValues = instance.getValues();
        Test.stopTest();

        Assert.isTrue(actualValues.size() > 0, 'There should be more than 0 values');
        Assert.isTrue(actualValues.containsAllRows(), 'All rows should be returned (true)');
        Assert.areEqual('(GMT+14:00) Line Islands Time (Pacific/Kiritimati)', actualValues.get(0).getValue(), 'The first value should be (GMT+14:00) Line Islands Time (Pacific/Kiritimati)');
    }
}