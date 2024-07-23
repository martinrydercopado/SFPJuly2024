@isTest
public with sharing class EnvironmentCreateTest {

    @TestSetup
    private static void createData() {
        setup();
    }

    @isTest
    private static void testEnvironmentCreate() {
        System.runAs(getRunAsUser()) {
            prepareTestData();
            Test.startTest();

           Id environmentDefinitionId = defs[0].Id;

            // Ensure there are no orgs created
            EnvironmentOrg__c[] envOrgs = [SELECT Id FROM EnvironmentOrg__c WHERE EnvironmentDefinition__c = :environmentDefinitionId];
            System.assertEquals(1, envOrgs.size());

            EnvironmentCreate.Request request = new EnvironmentCreate.Request();
            request.environmentDefinitionId = environmentDefinitionId;
            EnvironmentCreate.Response response = EnvironmentCreate.run(new EnvironmentCreate.Request[]{request})[0];

            EnvironmentOrg__c envOrg = [SELECT Status__c, ExpirationDate__c, Environment__c, LastJobExecutionId__c 
                FROM EnvironmentOrg__c WHERE Id = :response.environmentOrgId WITH USER_MODE];
            System.assertEquals('Available', envOrg.Status__c);

            // The Job template would have called this Rest Resource ...
            RestRequest rest = new RestRequest();
            rest.requestUri = 'https://copado.com';
            rest.httpMethod = 'POST';
            rest.params.put('action', 'saveOrg');
            rest.params.put('jobExecutionId', response.jobExecutionId);
            rest.params.put('newOrgId', UserInfo.getOrganizationId());
            rest.params.put('sfdxUrl', 'copado-test');
            rest.params.put('environmentOrgId', response.environmentOrgId);
            rest.params.put('environmentDefinitionId', request.environmentDefinitionId);
            RestContext.request = rest;
            // Call the method to test
            EnvironmentSaveActions.save();

            Test.stopTest();
            envOrg = [SELECT Status__c, ExpirationDate__c, Environment__c, LastJobExecutionId__c
                FROM EnvironmentOrg__c WHERE Id = :response.environmentOrgId WITH USER_MODE];
            System.assertEquals('Created', envOrg.Status__c);

            // check that now there is a single new org
            envOrgs = [SELECT Id FROM EnvironmentOrg__c WHERE EnvironmentDefinition__c = :environmentDefinitionId];
            System.assertEquals(2, envOrgs.size());
        }
    }

    @isTest
    private static void testFlowActions() {
        System.runAs(getRunAsUser()) {
            prepareTestData();
            Test.startTest();

            {
                EnvironmentFlowActions.Request request = new EnvironmentFlowActions.Request();
                request.action = 'EnvironmentCreate';
                request.environmentDefinitionId = defs[0].Id;
                EnvironmentFlowActions.Response response = EnvironmentFlowActions.run(new EnvironmentFlowActions.Request[]{request})[0];

                System.assertEquals(1, response.personas.size());
                System.assertEquals(0, response.pipelineEnvironments.size());
            }

            {
                EnvironmentFlowActions.Request request = new EnvironmentFlowActions.Request();
                request.action = 'EnvironmentUserCreate';
                request.environmentDefinitionId = defs[0].Id;
                EnvironmentFlowActions.Response response = EnvironmentFlowActions.run(new EnvironmentFlowActions.Request[]{request})[0];

                System.assertEquals(1, response.personas.size());
                System.assertEquals(null, response.pipelineEnvironments);
            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testEnvironmentCreateWithUser() {
        System.runAs(getRunAsUser()) {
            prepareTestData();
            Test.startTest();

            EnvironmentCreate.Request request = new EnvironmentCreate.Request();
            request.environmentDefinitionId = defs[0].Id;
            request.environmentPersonaIds = new Id[]{personas[0].Id}; // environmentPersonaIds instead of environmentPersonaId only to get a little more coverage
            EnvironmentCreate.Response response = EnvironmentCreate.run(new EnvironmentCreate.Request[]{request})[0];

            Test.stopTest();
            EnvironmentOrg__c envOrg = [SELECT Status__c, ExpirationDate__c, Environment__c FROM EnvironmentOrg__c WHERE Id = :response.environmentOrgId];
            System.assertEquals('In Use', envOrg.Status__c);
        }
    }

    @isTest
    private static void testEnvironmentWithPooling() {
        System.runAs(getRunAsUser()) {
            prepareTestData();
            Test.startTest();

            Id environmentDefinitionId = defs[1].Id;

            // Ensure there are no orgs created
            EnvironmentOrg__c[] envOrgs = [SELECT Id FROM EnvironmentOrg__c WHERE EnvironmentDefinition__c = :environmentDefinitionId];
            System.assertEquals(0, envOrgs.size());

            // Request one org, and then another one will be created automatically
            EnvironmentCreate.Request request = new EnvironmentCreate.Request();
            request.environmentDefinitionId = environmentDefinitionId;
            EnvironmentCreate.Response response = EnvironmentCreate.run(new EnvironmentCreate.Request[]{request})[0];

            Test.stopTest();

            // check that now there are two orgs
            envOrgs = [SELECT Id FROM EnvironmentOrg__c WHERE EnvironmentDefinition__c = :environmentDefinitionId];
            System.assertEquals(2, envOrgs.size());
        }
    }

    @isTest
    private static void testEnvironmentCreateVariousErrors() {
        System.runAs(getRunAsUser()) {
            prepareTestData();
            Test.startTest();

            EnvironmentCreate.Request request = new EnvironmentCreate.Request();
            request.environmentDefinitionId = defs[0].Id;
            try{
                EnvironmentCreate.Response response = EnvironmentCreate.run(new EnvironmentCreate.Request[]{request, request})[0];
                System.assert(false, 'Should throw an error');
            }catch(Exception e) {
            }

            try{
                EnvironmentCommons.errorIf(true, 'Expected error');
                System.assert(false, 'Expected error');
            }catch(EnvironmentCommons.AppException e) {
                System.assert(true, 'Expected error');
            }

            EnvironmentCommons.errorIfInvalidJson('', true, 'No error should be thrown');

            try{
                EnvironmentCommons.errorIfInvalidJson('', false, 'Expected error');
                System.assert(false, 'Expected error');
            }catch(EnvironmentCommons.AppException e) {
                System.assert(true, 'Expected error');
            }

            try{
                EnvironmentCommons.errorIfInvalidJson('{', false, 'Expected error');
                System.assert(false, 'Expected error');
            }catch(EnvironmentCommons.AppException e) {
                System.assert(true, 'Expected error');
            }
            
            Test.stopTest();
        }
    }


    // Data Creation. Shared with other tests

    @testVisible
    private static EnvironmentDefinition__c[] defs = new EnvironmentDefinition__c[]{};

    @testVisible
    private static EnvironmentPersona__c[] personas = new EnvironmentPersona__c[]{};

    @testVisible
    private static EnvironmentOrg__c existingEnvOrg;

    @testVisible
    private static EnvironmentUser__c existingUser;

    @testVisible
    private static copado__Environment__c sandbox;

    @testVisible
    private static void prepareTestData() {
        copado__Git_Repository__c repository = new copado__Git_Repository__c(Name = 'copado-unit-test');
        insert repository;

        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'copado-unit-test', 
            copado__Platform__c = 'Other', 
            copado__Git_Repository__c = repository.Id);
        insert pipeline;

        copado__Project__c project = new copado__Project__c(Name = 'copado-unit-test', 
            copado__Deployment_Flow__c = pipeline.Id);
        insert project;

        copado__Environment__c env = new copado__Environment__c(
            Name = 'copado-unit-test'
        );
        insert env;

        copado__System_Property__c s = new copado__System_Property__c(Name='ENVIRONMENT_MANAGER_AUTH', 
        copado__API_Name__c='ENVIRONMENT_MANAGER_AUTH', copado__Environment__c=env.Id, copado__Is_Sensitive__c=true);
        insert s;

        sandbox = new copado__Environment__c(
            Name = 'copado-unit-test-sandbox'
        );
        insert sandbox;

        copado__JobTemplate__c template = new copado__JobTemplate__c(Name='copadoenvmgr_create_org', copado__Version__c=1);
        insert template;

        defs.add( new EnvironmentDefinition__c(
            Name='Test 1',
            Status__c='Ready',
            OrgType__c='Other',
            DefaultBranch__c='',
            ParentEnvironment__c=env.Id,
            PipelineDestinationEnvId__c=null,
            Project__c=project.Id,
            JobTemplate__c=template.Id,
            DeleteJobTemplate__c=template.Id
        ) );

        defs.add( new EnvironmentDefinition__c(
            Name='Test 2 (pool)',
            Status__c='Ready',
            OrgType__c='Other',
            DefaultBranch__c='main',
            DesiredAvailableOrgs__c=1,
            ParentEnvironment__c=env.Id,
            PipelineDestinationEnvId__c=null,
            Project__c=project.Id,
            JobTemplate__c=template.Id
        ) );

        insert defs;

        personas.add(new EnvironmentPersona__c(
            EnvironmentDefinition__c=defs[0].Id,
            Username__c='dummy',
            JobTemplate__c=template.Id,
            DeleteJobTemplate__c=template.Id
        ));
        insert personas;

        existingEnvOrg = new EnvironmentOrg__c(
            Name='copado-unit-test',
            EnvironmentDefinition__c=defs[0].Id
        );
        insert existingEnvOrg;

        existingUser = new EnvironmentUser__c(
            Name='copado-unit-test',
            Status__c='In use',
            EnvironmentOrg__c=existingEnvOrg.Id,
            EnvironmentPersona__c=personas[0].Id
        );
        insert existingUser;

    }

    // setup methods. Also shared with other tests

    @testVisible
    private static void setup() {
        User runAsUser = createUser();
        assignPermissionSet(runAsUser.Id);
        System.runAs(runAsUser) {
            assignLicense(runAsUser.Id);
        }
    }

    @testVisible
    private static User createUser() {
        User runAsUser = new User(
            LastName = 'UserLastName',
            Username = 'username@myemail.com',
            Email = 'username@myemail.com',
            Alias = 'MyAlias',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE UserType = 'Standard' AND PermissionsPrivacyDataAccess = false AND PermissionsSubmitMacrosAllowed = true AND PermissionsMassInlineEdit = true LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert runAsUser;
        return runAsUser;
    }

    @testVisible
    private static User getRunAsUser() {
        List<User> runAsUsers = [SELECT Id FROM User WHERE Username = 'username@myemail.com'];
        return runAsUsers[0];
    }

    @testVisible
    private static void assignLicense(Id userId) {
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense userLicense = new copado.GlobalAPI.UserLicense();
        userLicense.isCCMEnabled = true;
        userLicense.isCopadoEnabled = true;
        userLicense.userId = userId;
        copadoGlobalAPI.upsertCopadoLicense(userLicense);
    }

    @testVisible
    private static void assignPermissionSet(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        Set<String> permissions = new Set<String>{'Copado_User', 'Copado_Functions', 'Copado_Job_Engine', 'Environment_Manager_User'};
        for (PermissionSet permission : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissions]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permission.Id));
        }
        insert assignments;
    }
}