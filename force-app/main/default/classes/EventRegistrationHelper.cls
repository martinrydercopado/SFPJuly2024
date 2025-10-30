public class EventRegistrationHelper {
    
    /**
     * Validates event registration data
     * @param events List of Event_Registration__c records to validate
     * @return Map of event IDs to validation messages
     */
    public static Map<Id, String> validateEventData(List<Event_Registration__c> events) {
        Map<Id, String> validationResults = new Map<Id, String>();
        
        for (Event_Registration__c evt : events) {
            // Check capacity
            if (evt.Registered_Attendees__c > evt.Max_Capacity__c) {
                validationResults.put(evt.Id, 'Registered attendees exceed maximum capacity');
            }
            
            // Check registration deadline
            if (evt.Registration_Deadline__c != null && evt.Event_Date__c != null) {
                if (evt.Registration_Deadline__c >= evt.Event_Date__c) {
                    validationResults.put(evt.Id, 'Registration deadline must be before event date');
                }
            }
            
            // Check virtual event requirements
            if (evt.Is_Virtual__c && String.isBlank(evt.Meeting_Link__c)) {
                validationResults.put(evt.Id, 'Virtual events require a meeting link');
            }
            
            // Check budget variance
            if (evt.Actual_Cost__c != null && evt.Budget_Amount__c != null) {
                Decimal variance = ((evt.Actual_Cost__c - evt.Budget_Amount__c) / evt.Budget_Amount__c) * 100;
                if (Math.abs(variance) > 20) {
                    validationResults.put(evt.Id, 'Cost variance exceeds 20% threshold');
                }
            }
        }
        
        return validationResults;
    }
    
    /**
     * Calculates event statistics
     * @param eventIds Set of Event_Registration__c IDs
     * @return Map of statistics
     */
    public static Map<String, Decimal> calculateEventStats(Set<Id> eventIds) {
        Map<String, Decimal> stats = new Map<String, Decimal>();
        
        List<Event_Registration__c> events = [
            SELECT Id, Max_Capacity__c, Registered_Attendees__c, Budget_Amount__c, Actual_Cost__c
            FROM Event_Registration__c
            WHERE Id IN :eventIds
        ];
        
        Decimal totalCapacity = 0;
        Decimal totalRegistered = 0;
        Decimal totalBudget = 0;
        Decimal totalCost = 0;
        
        for (Event_Registration__c evt : events) {
            totalCapacity += evt.Max_Capacity__c != null ? evt.Max_Capacity__c : 0;
            totalRegistered += evt.Registered_Attendees__c != null ? evt.Registered_Attendees__c : 0;
            totalBudget += evt.Budget_Amount__c != null ? evt.Budget_Amount__c : 0;
            totalCost += evt.Actual_Cost__c != null ? evt.Actual_Cost__c : 0;
        }
        
        stats.put('totalCapacity', totalCapacity);
        stats.put('totalRegistered', totalRegistered);
        stats.put('utilizationRate', totalCapacity > 0 ? (totalRegistered / totalCapacity) * 100 : 0);
        stats.put('totalBudget', totalBudget);
        stats.put('totalCost', totalCost);
        stats.put('budgetVariance', totalBudget > 0 ? ((totalCost - totalBudget) / totalBudget) * 100 : 0);
        
        return stats;
    }
}