@isTest
private class TaskUtilityTest {
  @isTest
  static void testTaskPriority() {
    String pri = TaskUtil.getTaskPriority('NY');
    System.assertEquals('Normal', pri);
  }
}