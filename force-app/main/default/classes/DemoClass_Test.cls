@isTest
private class DemoClass_Test {
    static testMethod void testMethod1() {
        System.Test.startTest();
        System.assert('Something1'.equalsIgnoreCase('Something1'));
        System.Test.stopTest();
    }
}
