@isTest
private class SupportTicketPriorityCalculatorTest {
    
    @isTest
    static void testBugReportPriority() {
        // Test Bug Report → Critical
        Support_Ticket__c ticket = new Support_Ticket__c(
            Customer_Name__c = 'Test Customer',
            Category__c = 'Bug Report',
            Description__c = 'Test bug'
        );
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(new List<Support_Ticket__c>{ticket});
        Test.stopTest();
        
        System.assertEquals('Critical', ticket.Priority__c, 'Bug Report should be Critical priority');
    }
    
    @isTest
    static void testTechnicalPriority() {
        // Test Technical → High
        Support_Ticket__c ticket = new Support_Ticket__c(
            Customer_Name__c = 'Test Customer',
            Category__c = 'Technical',
            Description__c = 'Test technical issue'
        );
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(new List<Support_Ticket__c>{ticket});
        Test.stopTest();
        
        System.assertEquals('High', ticket.Priority__c, 'Technical should be High priority');
    }
    
    @isTest
    static void testBillingPriority() {
        // Test Billing → Medium
        Support_Ticket__c ticket = new Support_Ticket__c(
            Customer_Name__c = 'Test Customer',
            Category__c = 'Billing',
            Description__c = 'Test billing question'
        );
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(new List<Support_Ticket__c>{ticket});
        Test.stopTest();
        
        System.assertEquals('Medium', ticket.Priority__c, 'Billing should be Medium priority');
    }
    
    @isTest
    static void testFeatureRequestPriority() {
        // Test Feature Request → Low
        Support_Ticket__c ticket = new Support_Ticket__c(
            Customer_Name__c = 'Test Customer',
            Category__c = 'Feature Request',
            Description__c = 'Test feature request'
        );
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(new List<Support_Ticket__c>{ticket});
        Test.stopTest();
        
        System.assertEquals('Low', ticket.Priority__c, 'Feature Request should be Low priority');
    }
    
    @isTest
    static void testGeneralInquiryPriority() {
        // Test General Inquiry → Low
        Support_Ticket__c ticket = new Support_Ticket__c(
            Customer_Name__c = 'Test Customer',
            Category__c = 'General Inquiry',
            Description__c = 'Test general question'
        );
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(new List<Support_Ticket__c>{ticket});
        Test.stopTest();
        
        System.assertEquals('Low', ticket.Priority__c, 'General Inquiry should be Low priority');
    }
    
    @isTest
    static void testNullCategoryDefaultPriority() {
        // Test null category → Medium (default)
        Support_Ticket__c ticket = new Support_Ticket__c(
            Customer_Name__c = 'Test Customer',
            Category__c = null,
            Description__c = 'Test no category'
        );
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(new List<Support_Ticket__c>{ticket});
        Test.stopTest();
        
        System.assertEquals('Medium', ticket.Priority__c, 'Null category should default to Medium priority');
    }
    
    @isTest
    static void testBulkProcessing() {
        // Test bulk processing with 200 records
        List<Support_Ticket__c> tickets = new List<Support_Ticket__c>();
        
        for (Integer i = 0; i < 200; i++) {
            String category;
            String expectedPriority;
            
            // Distribute across all categories
            Integer categoryIndex = Math.mod(i, 5);
            if (categoryIndex == 0) {
                category = 'Bug Report';
                expectedPriority = 'Critical';
            } else if (categoryIndex == 1) {
                category = 'Technical';
                expectedPriority = 'High';
            } else if (categoryIndex == 2) {
                category = 'Billing';
                expectedPriority = 'Medium';
            } else if (categoryIndex == 3) {
                category = 'Feature Request';
                expectedPriority = 'Low';
            } else {
                category = 'General Inquiry';
                expectedPriority = 'Low';
            }
            
            tickets.add(new Support_Ticket__c(
                Customer_Name__c = 'Bulk Customer ' + i,
                Category__c = category,
                Description__c = 'Bulk test ' + i
            ));
        }
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(tickets);
        Test.stopTest();
        
        // Verify all 200 records have correct priority
        for (Integer i = 0; i < 200; i++) {
            Integer categoryIndex = Math.mod(i, 5);
            String expectedPriority;
            
            if (categoryIndex == 0) {
                expectedPriority = 'Critical';
            } else if (categoryIndex == 1) {
                expectedPriority = 'High';
            } else if (categoryIndex == 2) {
                expectedPriority = 'Medium';
            } else {
                expectedPriority = 'Low';
            }
            
            System.assertEquals(expectedPriority, tickets[i].Priority__c, 
                'Bulk record ' + i + ' should have correct priority');
        }
    }
    
    @isTest
    static void testEmptyList() {
        // Test empty list handling
        List<Support_Ticket__c> emptyList = new List<Support_Ticket__c>();
        
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(emptyList);
        Test.stopTest();
        
        // Should not throw exception
        System.assertEquals(0, emptyList.size(), 'Empty list should remain empty');
    }
    
    @isTest
    static void testNullList() {
        // Test null list handling
        Test.startTest();
        SupportTicketPriorityCalculator.calculatePriority(null);
        Test.stopTest();
        
        // Should not throw exception - test passes if no exception thrown
        System.assert(true, 'Null list should be handled gracefully');
    }
}