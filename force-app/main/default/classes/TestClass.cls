public with sharing class TestClass {
    public TestClass() {
        Integer i = 0;
        for (Integer x = 0;x<10;x++) 
        {
            i++;
            System.debug('=======i:'+i);
        }
        System.debug('===========THIS TIME :' + System.now());
    }
}