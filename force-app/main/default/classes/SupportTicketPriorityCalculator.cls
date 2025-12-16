public class SupportTicketPriorityCalculator {
    // Constants for picklist values
    private static final String PRIORITY_CRITICAL = 'Critical';
    private static final String PRIORITY_HIGH = 'High';
    private static final String PRIORITY_MEDIUM = 'Medium';
    private static final String PRIORITY_LOW = 'Low';
    
    private static final String CATEGORY_BUG = 'Bug Report';
    private static final String CATEGORY_TECHNICAL = 'Technical';
    private static final String CATEGORY_BILLING = 'Billing';
    private static final String CATEGORY_FEATURE = 'Feature Request';
    private static final String CATEGORY_GENERAL = 'General Inquiry';
    
    /**
     * Calculates priority for Support Tickets based on category
     * @param tickets List of Support Ticket records
     */
    public static void calculatePriority(List<Support_Ticket__c> tickets) {
        if (tickets == null || tickets.isEmpty()) {
            return;
        }
        
        for (Support_Ticket__c ticket : tickets) {
            ticket.Priority__c = determinePriority(ticket.Category__c);
        }
    }
    
    /**
     * Determines priority based on category
     * @param category The ticket category
     * @return The calculated priority
     */
    private static String determinePriority(String category) {
        if (String.isBlank(category)) {
            return PRIORITY_MEDIUM;
        }
        
        switch on category {
            when 'Bug Report' {
                return PRIORITY_CRITICAL;
            }
            when 'Technical' {
                return PRIORITY_HIGH;
            }
            when 'Billing' {
                return PRIORITY_MEDIUM;
            }
            when 'Feature Request', 'General Inquiry' {
                return PRIORITY_LOW;
            }
            when else {
                return PRIORITY_MEDIUM;
            }
        }
    }
}