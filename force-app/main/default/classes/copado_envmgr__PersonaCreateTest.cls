@isTest
public with sharing class PersonaCreateTest {

    @TestSetup
    private static void createData() {
        EnvironmentCreateTest.setup();
    }

    @isTest
    private static void testEnvironmentCreate() {
        System.runAs(EnvironmentCreateTest.getRunAsUser()) {
            EnvironmentCreateTest.prepareTestData();
            Test.startTest();

            PersonaCreate.Request request = new PersonaCreate.Request();
            request.environmentPersonaId = EnvironmentCreateTest.personas[0].Id;
            request.environmentOrgId = EnvironmentCreateTest.existingEnvOrg.Id;
            PersonaCreate.Response response =  PersonaCreate.run(new PersonaCreate.Request[]{request})[0];

            Test.stopTest();
            EnvironmentUser__c envUser = [SELECT Status__c, ExpirationDate__c FROM EnvironmentUser__c WHERE Id = :response.envirionmentUserId];
            System.assertEquals('In Use', envUser.Status__c);
        }
    }
}