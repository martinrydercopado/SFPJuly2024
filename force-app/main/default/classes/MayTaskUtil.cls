public class MayTaskUtil {
    public static String getTaskPriority(String leadState) {
        // Validate input
        
        String taskPriority;
        if (leadState == 'CA') {
             taskPriority = 'High'; 
        } else {
             taskPriority = 'Normal';
        }
        
        if (String.isBlank(leadState) || leadState.length() > 2) {
            return null;
        }
        
        return taskPriority;
    }
}