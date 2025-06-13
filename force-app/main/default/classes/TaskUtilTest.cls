@IsTest
private class TaskUtilTest {
    @IsTest static void testGetTaskPriority() {
        // Test CA state
        String priority1 = TaskUtil.getTaskPriority('CA');
        System.assertEquals('High', priority1);
        
        // Test NY state
        String priority2 = TaskUtil.getTaskPriority('NY');
        System.assertEquals('High', priority2);
        
        // Test TX state
        String priority3 = TaskUtil.getTaskPriority('TX');
        System.assertEquals('Medium', priority3);
        
        // Test other state
        String priority4 = TaskUtil.getTaskPriority('AZ');
        System.assertEquals('Normal', priority4);
        
        // Test invalid input
        String priority5 = TaskUtil.getTaskPriority('');
        System.assertEquals(null, priority5);
        
        String priority6 = TaskUtil.getTaskPriority('ABC');
        System.assertEquals(null, priority6);
    }
    
    @IsTest static void testGetTaskUrgency() {
        // Test urgent case
        String urgency1 = TaskUtil.getTaskUrgency(8);
        System.assertEquals('Urgent', urgency1);
        
        // Test high urgency case
        String urgency2 = TaskUtil.getTaskUrgency(5);
        System.assertEquals('High', urgency2);
        
        // Test normal case
        String urgency3 = TaskUtil.getTaskUrgency(2);
        System.assertEquals('Normal', urgency3);
        
        // Test null case
        String urgency4 = TaskUtil.getTaskUrgency(null);
        System.assertEquals('Normal', urgency4);
    }
}