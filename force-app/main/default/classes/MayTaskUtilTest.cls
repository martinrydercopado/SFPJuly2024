@isTest
private class MayTaskUtilTest {
    @isTest static void testTaskPriority() {
        String pri = MayTaskUtil.getTaskPriority('NY');
        System.assertEquals('Normal', pri);
    }
    @isTest static void testTaskHighPriority() {
        String pri = MayTaskUtil.getTaskPriority('CA');
        System.assertEquals('High', pri);
    }
    @isTest static void testTaskPriorityInvalid() {
        String pri = MayTaskUtil.getTaskPriority('Montana');
        System.assertEquals(null, pri);
    }
}