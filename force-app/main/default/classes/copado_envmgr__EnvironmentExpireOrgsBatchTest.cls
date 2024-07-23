@isTest
public with sharing class EnvironmentExpireOrgsBatchTest {

    @TestSetup
    private static void createData() {
        EnvironmentCreateTest.setup();
    }

    @isTest
    private static void testExpireOrgs() {
        System.runAs(EnvironmentCreateTest.getRunAsUser()) {
            EnvironmentCreateTest.prepareTestData();

            EnvironmentOrg__c rec = new EnvironmentOrg__c(
                Name='copado-unit-test-expired',
                EnvironmentDefinition__c=EnvironmentCreateTest.defs[0].Id,
                Environment__c=EnvironmentCreateTest.sandbox.Id,
                ExpirationDate__c=System.today().addDays(-1)
            );
            insert rec;

            Test.startTest();
            EnvironmentExpireOrgsBatch.run();
            Test.stopTest();

            rec = [SELECT Status__c, isExpired__c FROM EnvironmentOrg__c WHERE Id = :rec.Id];
            System.debug(rec);
            System.assertEquals('Deleted', rec.Status__c);
        }
    }
}