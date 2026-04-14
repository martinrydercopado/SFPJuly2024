@isTest
public class EventRegistrationHelperTest {
    
    @testSetup
    static void setupTestData() {
        List<Event_Registration__c> testEvents = new List<Event_Registration__c>();
        
        testEvents.add(new Event_Registration__c(
            Event_Name__c = 'Test Conference',
            Event_Date__c = Date.today().addDays(30),
            Max_Capacity__c = 100,
            Registered_Attendees__c = 75,
            Budget_Amount__c = 10000,
            Actual_Cost__c = 9500,
            Registration_Deadline__c = Date.today().addDays(15),
            Is_Virtual__c = false,
            Event_Type__c = 'Conference',
            Status__c = 'Open for Registration'
        ));
        
        testEvents.add(new Event_Registration__c(
            Event_Name__c = 'Virtual Workshop',
            Event_Date__c = Date.today().addDays(15),
            Max_Capacity__c = 50,
            Registered_Attendees__c = 30,
            Budget_Amount__c = 5000,
            Is_Virtual__c = true,
            Meeting_Link__c = 'https://zoom.us/test',
            Registration_Deadline__c = Date.today().addDays(7),
            Event_Type__c = 'Workshop',
            Status__c = 'Open for Registration'
        ));
        
        insert testEvents;
    }
    
    @isTest
    static void testValidateEventData_OverCapacity() {
        Event_Registration__c evt = new Event_Registration__c(
            Event_Name__c = 'Overcapacity Event',
            Max_Capacity__c = 50,
            Registered_Attendees__c = 60,
            Event_Date__c = Date.today().addDays(10)
        );
        insert evt;
        
        Test.startTest();
        Map<Id, String> results = EventRegistrationHelper.validateEventData(new List<Event_Registration__c>{evt});
        Test.stopTest();
        
        System.assert(results.containsKey(evt.Id), 'Should have validation error');
        System.assert(results.get(evt.Id).contains('exceed'), 'Should indicate capacity issue');
    }
    
    @isTest
    static void testValidateEventData_InvalidDeadline() {
        Event_Registration__c evt = new Event_Registration__c(
            Event_Name__c = 'Invalid Deadline Event',
            Event_Date__c = Date.today().addDays(10),
            Registration_Deadline__c = Date.today().addDays(15),
            Max_Capacity__c = 100,
            Registered_Attendees__c = 50
        );
        insert evt;
        
        Test.startTest();
        Map<Id, String> results = EventRegistrationHelper.validateEventData(new List<Event_Registration__c>{evt});
        Test.stopTest();
        
        System.assert(results.containsKey(evt.Id), 'Should have validation error');
        System.assert(results.get(evt.Id).contains('deadline'), 'Should indicate deadline issue');
    }
    
    @isTest
    static void testValidateEventData_VirtualNoLink() {
        Event_Registration__c evt = new Event_Registration__c(
            Event_Name__c = 'Virtual Event No Link',
            Is_Virtual__c = true,
            Event_Date__c = Date.today().addDays(10),
            Max_Capacity__c = 100,
            Registered_Attendees__c = 50
        );
        insert evt;
        
        Test.startTest();
        Map<Id, String> results = EventRegistrationHelper.validateEventData(new List<Event_Registration__c>{evt});
        Test.stopTest();
        
        System.assert(results.containsKey(evt.Id), 'Should have validation error');
        System.assert(results.get(evt.Id).contains('meeting link'), 'Should indicate missing link');
    }
    
    @isTest
    static void testCalculateEventStats() {
        List<Event_Registration__c> events = [SELECT Id FROM Event_Registration__c];
        Set<Id> eventIds = new Map<Id, Event_Registration__c>(events).keySet();
        
        Test.startTest();
        Map<String, Decimal> stats = EventRegistrationHelper.calculateEventStats(eventIds);
        Test.stopTest();
        
        System.assertNotEquals(null, stats.get('totalCapacity'), 'Should calculate total capacity');
        System.assertNotEquals(null, stats.get('totalRegistered'), 'Should calculate total registered');
        System.assertNotEquals(null, stats.get('utilizationRate'), 'Should calculate utilization rate');
        System.assert(stats.get('utilizationRate') >= 0 && stats.get('utilizationRate') <= 100, 'Utilization should be percentage');
    }
    
    @isTest
    static void testCalculateEventStats_BudgetVariance() {
        List<Event_Registration__c> events = [SELECT Id FROM Event_Registration__c WHERE Budget_Amount__c != null];
        Set<Id> eventIds = new Map<Id, Event_Registration__c>(events).keySet();
        
        Test.startTest();
        Map<String, Decimal> stats = EventRegistrationHelper.calculateEventStats(eventIds);
        Test.stopTest();
        
        System.assertNotEquals(null, stats.get('totalBudget'), 'Should calculate total budget');
        System.assertNotEquals(null, stats.get('budgetVariance'), 'Should calculate budget variance');
    }
    
    @isTest
    static void testValidateEventData_ValidEvent() {
        Event_Registration__c evt = new Event_Registration__c(
            Event_Name__c = 'Valid Event',
            Event_Date__c = Date.today().addDays(30),
            Registration_Deadline__c = Date.today().addDays(15),
            Max_Capacity__c = 100,
            Registered_Attendees__c = 50,
            Budget_Amount__c = 10000,
            Actual_Cost__c = 9800,
            Is_Virtual__c = true,
            Meeting_Link__c = 'https://zoom.us/valid'
        );
        insert evt;
        
        Test.startTest();
        Map<Id, String> results = EventRegistrationHelper.validateEventData(new List<Event_Registration__c>{evt});
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Valid event should have no validation errors');
    }
}