@isTest
private class DemoClass_Test {
    static testMethod void testMethod1() {
        System.Test.startTest();
        System.assert('Something'.equalsIgnoreCase('Something'));
        System.Test.stopTest();
    }
}
