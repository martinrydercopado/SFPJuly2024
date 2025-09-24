public class TaskUtil {
    public static String getTaskPriority(String leadState) {
        // Enhanced validation and priority logic
        if (String.isBlank(leadState) || leadState.length() > 2) {
            return null;
        }
        
        String taskPriority;
        if (leadState == 'CA' || leadState == 'NY') {
            taskPriority = 'High';
        } else if (leadState == 'TX') {
            taskPriority = 'Medium';
        } else {
            taskPriority = 'Normal';
        }
        
        if (String.isBlank(leadState) || leadState.length() > 2) {
            return null;
        }
        
        return taskPriority;
    }
}