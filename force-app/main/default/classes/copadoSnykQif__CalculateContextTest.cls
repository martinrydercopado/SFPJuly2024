@isTest
private with sharing class CalculateContextTest {
    @isTest
    private static void testCalculate() {
        System.runAs([SELECT Id FROM User WHERE Username = 'username@myemail.com'][0]) {
            // Setup
            TestDataFactory.createDefaultTestData('Salesforce');
            copado__User_Story__c userStory = [SELECT Id, Name FROM copado__User_Story__c WHERE copado__Project__c = :TestDataFactory.project.Id AND copado__Base_Branch__c = ''];
            copado__User_Story__c userStoryWithBranch = [SELECT Id, Name FROM copado__User_Story__c WHERE copado__Project__c = :TestDataFactory.project.Id AND copado__Base_Branch__c = 'user'];
            copado__Promotion__c promotion = [SELECT Id, Name FROM copado__Promotion__c WHERE copado__Project__c = :TestDataFactory.project.Id];

            // Exercise: Run with copado__User_Story_Commit__c
            {
                CalculateContext context = new CalculateContext();
                String obj = context.execute(TestDataFactory.jobStepWithCommit.Id);
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(obj);
                Assert.areEqual('feature/' + userStory.Name, result.get('branch'));
                Assert.areEqual(userStory.Id, result.get('userStoryId'));
                Assert.areEqual('main', result.get('baseBranch'));
            }
            // Exercise: Run with copado__Test__c
            {
                CalculateContext context = new CalculateContext();
                String obj = context.execute(TestDataFactory.jobStepWithTest.Id);
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(obj);
                Assert.areEqual('feature/' + userStoryWithBranch.Name, result.get('branch'));
                Assert.areEqual(userStoryWithBranch.Id, result.get('userStoryId'));
                Assert.areEqual('user', result.get('baseBranch'));
            }
            // Exercise: Run with copado__Promotion__c
            {
                CalculateContext context = new CalculateContext();
                String obj = context.execute(TestDataFactory.jobStepWithPromotion.Id);
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(obj);
                Assert.areEqual('promotion/' + promotion.Name, result.get('branch'));
                Assert.areEqual(promotion.Id, result.get('promotionId'));
                Assert.areEqual('dev', result.get('baseBranch'));
            }
        }
    }

    @TestSetup
    private static void makeData() {
        User runAsUser = new User(
            LastName = 'UserLastName',
            Username = 'username@myemail.com',
            Email = 'username@myemail.com',
            Alias = 'MyAlias',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert runAsUser;

        System.runAs(runAsUser) {
            copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
            copado.GlobalAPI.UserLicense userLicense = new copado.GlobalAPI.UserLicense();
            userLicense.isCCMEnabled = true;
            userLicense.isCopadoEnabled = true;
            userLicense.userId = runAsUser.Id;
            copadoGlobalAPI.upsertCopadoLicense(userLicense);

            PermissionSetAssignment copado = new PermissionSetAssignment();
            copado.PermissionSetId = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Copado_User' LIMIT 1].Id;
            copado.AssigneeId = runAsUser.Id;
            insert copado;
        }
    }
}