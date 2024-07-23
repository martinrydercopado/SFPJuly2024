@isTest
public with sharing class EnvironmentExpireUsersBatchTest {

    @TestSetup
    private static void createData() {
        EnvironmentCreateTest.setup();
    }

    @isTest
    private static void testExpireUser() {
        System.runAs(EnvironmentCreateTest.getRunAsUser()) {
            EnvironmentCreateTest.prepareTestData();

            EnvironmentUser__c existingUser = new EnvironmentUser__c(
                Name='copado-unit-test',
                Status__c='In use',
                EnvironmentOrg__c=EnvironmentCreateTest.existingEnvOrg.Id,
                EnvironmentPersona__c=EnvironmentCreateTest.personas[0].Id,
                ExpirationDate__c=System.today().addDays(-1)
            );
            insert existingUser;
    
            Test.startTest();
            EnvironmentExpireUsersBatch.run();
            Test.stopTest();

            EnvironmentUser__c envUser = [SELECT Status__c FROM EnvironmentUser__c WHERE Id = :existingUser.Id];
            System.debug(envUser);
            System.assertEquals('Deleted', envUser.Status__c);
        }
    }
}