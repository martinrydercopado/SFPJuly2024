@SuppressWarnings('PMD')
@IsTest
public with sharing class TestDataFactory {
    /**
     * Create Sample copado__Git_Repository__c and return it's instance
     */
    public static copado__Git_Repository__c createGitRepository() {
        copado__Git_Repository__c repo = new copado__Git_Repository__c();
        repo.Name = 'test repo';
        return repo;
    }

    /**
     * Create Sample copado__Deployment_Flow__c and return it's instance
     */
    public static copado__Deployment_Flow__c createDeploymentFlow(
        String name,
        Boolean isActive,
        String gitRepositoryId,
        Boolean enableDX
    ) {
        // NOPMD : Supressing rule to avoid large refactor.
        copado__Deployment_Flow__c deploymentFlow = new copado__Deployment_Flow__c();
        deploymentFlow.Name = name;
        deploymentFlow.copado__Active__c = isActive;
        deploymentFlow.copado__Git_Repository__c = gitRepositoryId;
        deploymentFlow.copado__Enable_Copado_DX__c = enableDX;
        deploymentFlow.copado__Main_Branch__c = 'master';
        return deploymentFlow;
    }

    /**
     * Create Sample copado__Deployment_Flow_Step__c and return it's instance
     */
    public static copado__Deployment_Flow_Step__c createDeploymentFlowStep( // NOPMD : Supressing rule to avoid large refactor.
        String sourceEnvironmentId,
        String destinationEnvironmentId,
        String deploymentFlowId,
        String scratchOrgDestination
    ) {
        copado__Deployment_Flow_Step__c deploymentFlowStep = new copado__Deployment_Flow_Step__c();
        deploymentFlowStep.copado__Source_Environment__c = sourceEnvironmentId;
        deploymentFlowStep.copado__Destination_Environment__c = destinationEnvironmentId;
        deploymentFlowStep.copado__Deployment_Flow__c = deploymentFlowId;
        deploymentFlowStep.copado__Enable_as_Scratch_Org_Destination__c = scratchOrgDestination;

        return deploymentFlowStep;
    }

    /**
     * Create Sample copado__Environment__c and return it's instance
     */
    public static copado__Environment__c createTestEnvironment(String name, String type) {
        copado__Environment__c environment = new copado__Environment__c();
        environment.copado__Type__c = type;
        environment.Name = name;
        environment.copado__Platform__c = 'Marketing Cloud';
        return environment;
    }

    /**
     * Create Sample copado__Environmental_Variable__c and return it's instance
     */
    public static copado__Environmental_Variable__c createTestEnvironmentVariable(
        String environmentId,
        String name,
        String value
    ) {
        copado__Environmental_Variable__c environmentVariable = new copado__Environmental_Variable__c();
        environmentVariable.Name = name;
        environmentVariable.copado__Value__c = value;
        environmentVariable.copado__Environment__c = environmentId;
        return environmentVariable;
    }

    /**
     * Create Sample copado__Project__c and return it's instance
     */
    public static copado__Project__c createTestProject(String pipelineId) {
        copado__Project__c proj = new copado__Project__c(Name = 'Test Project Name');
        proj.copado__Status__c = 'Draft';
        proj.copado__Description__c = 'My Test description';
        proj.copado__Start_Date__c = System.today();
        proj.copado__Deployment_Flow__c = pipelineId;
        return proj;
    }

    /**
     * Create Sample copado__User_Story__c and return it's instance
     */
    public static copado__User_Story__c createUserStory( // NOPMD : Supressing rule to avoid large refactor.
        String userStoryTitle,
        String status,
        String sprintId,
        String projectId,
        String environmentId
    ) {
        copado__User_Story__c userStory = new copado__User_Story__c();
        userStory.copado__User_Story_Title__c = userStoryTitle;
        userStory.copado__Status__c = status;
        userStory.copado__Sprint__c = sprintId;
        userStory.copado__Project__c = projectId;
        userStory.copado__Environment__c = environmentId;
        return userStory;
    }
    

    /**
     * Create Sample copado__User_Story__c and return it's instance
     */
    public static copado__User_Story_Commit__c createUserStoryCommit( // NOPMD : Supressing rule to avoid large refactor.
        String commitMessage,
        String status,
        String userStory
    ) {
        copado__User_Story_Commit__c userStoryCommit = new copado__User_Story_Commit__c();
        userStoryCommit.copado__User_Story__c = userStory;

        return userStoryCommit;
    }

    /**
     * Create Sample ContentVersion and return it's instance
     */
    public static ContentVersion createFile(String title) {
        ContentVersion contentVersionRecord = new ContentVersion();
        contentVersionRecord.ContentLocation = 'S'; // 'S' = a Salesforce File
        contentVersionRecord.VersionData = Blob.valueOf('sample content');
        contentVersionRecord.Title = title;
        contentVersionRecord.PathOnClient = title;
        return contentVersionRecord;
    }

    /**
     * Create Sample ContentDocumentLink and return it's instance
     */
    public static ContentDocumentLink createFileLink(
        String contentVersionRecordId,
        String entityId
    ) {
        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersionRecordId
        ]
        .ContentDocumentId;
        ContentDocumentLink contentDocumentLinkRecord = new ContentDocumentLink();
        contentDocumentLinkRecord.LinkedEntityId = entityId;
        contentDocumentLinkRecord.ContentDocumentId = contentDocumentId;
        contentDocumentLinkRecord.shareType = 'V';
        return contentDocumentLinkRecord;
    }

    /**
     * This method creates a User with the Standard User profile for testing purposes - with username: test.username@testdomain.com
     */
    public static User createStandardUser() {
        return createUser('LastName', 'test2@test2.com', 'test.username@testdomain.com', 'alias2');
    }

    /**
     * This method creates a User with the Standard User profile for testing purposes - with username: invalidtest.username@testdomain.com
     */
    public static User createInvalidUser() {
        return createUser(
            'LastName',
            'test1@test1.com',
            'invalidtest.username@testdomain.com',
            'alias1'
        );
    }

    /**
     * This method to create a user for testing purposes.
     */
    public static User createUser(String lastName, String email, String username, String alias) {
        User standardUser = new User();
        standardUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        standardUser.LastName = lastName;
        standardUser.Email = email;
        standardUser.Username = username;
        standardUser.Alias = alias;
        standardUser.TimeZoneSidKey = 'America/Los_Angeles';
        standardUser.EmailEncodingKey = 'UTF-8';
        standardUser.LanguageLocaleKey = 'en_US';
        standardUser.LocaleSidKey = 'en_US';
        return standardUser;
    }

    /**
     * This method assigns the Copado_ALM_User permission to a selected user for testing purposes.
     */
    public static List<PermissionSetAssignment> createPermissions(
        Id userId,
        Set<String> permissionSetNames
    ) {
        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN :permissionSetNames
        ];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet thisPermission : permissionSets) {
            PermissionSetAssignment assignment = new PermissionSetAssignment();
            assignment.PermissionSetId = thisPermission.Id;
            assignment.AssigneeId = userId;
            assignments.add(assignment);
        }
        return assignments;
    }

    /**
     * This method assigns the All required permission to a selected user for testing purposes.
     */
    public static List<PermissionSetAssignment> createRequiredPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        assignments.addAll(
            createPermissions(
                userId,
                new Set<String>{ 'Copado_Job_Engine', 'Copado_User', 'Copado_Functions' }
            )
        );
        return assignments;
    }
    
     /**
     * This method assigns the necessary licenses to a user in order to let the user update promotions and so on
     */
    public static void assignLicense(Id userId) {
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense userLicense = new copado.GlobalAPI.UserLicense();
        userLicense.isCCMEnabled = true;
        userLicense.isCopadoEnabled = true;
        userLicense.userId = userId;
        copadoGlobalAPI.upsertCopadoLicense(userLicense);
    }

    public static copado__Deployment_Flow__c pipeline;
    public static copado__Promotion__c promotion;
    public static copado__User_Story__c userStory;
    public static copado__User_Story_Commit__c userStoryCommit;
    public static copado__Deployment__c deployment;
    public static copado__JobStep__c jobStepWithPromotion;
    public static copado__JobStep__c jobStepWithCommit;
    public static copado__JobStep__c jobStepWithTest;
    public static copado__Project__c project;

    @testVisible
    private static void createDefaultTestData(String platform) {
        // default test data
        copado__Git_Repository__c repository = new copado__Git_Repository__c(Name='test repo');
        insert repository;
        
        pipeline = new copado__Deployment_Flow__c(
            copado__Active__c=true,
            copado__Platform__c=platform,
            copado__Main_Branch__c='main',
            copado__Git_Repository__c=repository.Id
        );
        insert pipeline;
        
        project = new copado__Project__c(copado__Deployment_Flow__c=pipeline.id);
        insert project;
        
        copado__Environment__c environment = new copado__Environment__c(name='environmentName', copado__Platform__c=platform);
        insert environment;
        
        copado__Org__c credentials = new copado__Org__c(copado__Environment__c=environment.id);
        insert credentials;
        
        copado__Deployment_Flow_Step__c pipelineConnection = new copado__Deployment_Flow_Step__c(
            copado__Source_Environment__c=environment.id,
            copado__Destination_Environment__c=environment.id,
            copado__Deployment_Flow__c=pipeline.id,
            copado__Branch__c='dev'
        );
        insert pipelineConnection;
        
        promotion = new copado__Promotion__c(
            copado__Project__c = project.id,
            copado__Source_Environment__c=environment.id
        );
        insert promotion;
        
        deployment = new copado__Deployment__c(copado__Promotion__c = promotion.id);
        insert deployment;
        
        userStory = new copado__User_Story__c(
            copado__Environment__c=environment.id,
            copado__Project__c=project.id,
            copado__Functional_Specifications__c='<p>Hello</p>',
            copado__Project__r=project
        );
        insert userStory;
        
        copado__User_Story__c userStoryWithBranch = new copado__User_Story__c(
            copado__Environment__c=environment.id,
            copado__Project__c=project.id,
            copado__Functional_Specifications__c='<p>Hello</p>',
            copado__Project__r=project,
            copado__Base_Branch__c='user'
        );
        insert userStoryWithBranch;

        copado__Git_Org_Commit__c orgCommit = new copado__Git_Org_Commit__c(
            copado__Commit_Date__c = datetime.now(),
            copado__Commit_Message__c = 'This is a commit message',
            copado__Org__c = credentials.Id
        );
        insert orgCommit;

        userStoryCommit = new copado__User_Story_Commit__c(copado__User_Story__c=userStory.Id, copado__Snapshot_Commit__c=orgCommit.Id);
        insert userStoryCommit;

        copado__JobTemplate__c templateWithCommit = new copado__JobTemplate__c();
            templateWithCommit.Name = 'MC_Retrieve_Action_With_Commit';
            templateWithCommit.copado__Version__c = 1;
            templateWithCommit.copado__VolumeOptions__c = '[{ "name": "volumeSize", "value": "1" }, { "name": "volumeTTL", "value": "1440" },{ "name": "volumeEnabled", "value": "true" }]';
        insert templateWithCommit;
        
        copado__JobExecution__c jobExecutionWithCommit = new copado__JobExecution__c(copado__UserStoryCommit__c=userStoryCommit.Id);
        insert jobExecutionWithCommit;
        
        jobStepWithCommit = new copado__JobStep__c(Name = 'stepWithoutAPromotion',
                copado__JobTemplate__c = templateWithCommit.Id,
                copado__Type__c = 'Manual',
                copado__PipelineId__c = pipeline.Id,
                copado__JobExecution__c=jobExecutionWithCommit.Id);
        insert jobStepWithCommit;
        
        copado__Promoted_User_Story__c promotedUserStory = new copado__Promoted_User_Story__c(copado__Promotion__c=promotion.id, copado__User_Story__c=userStory.id);
        insert promotedUserStory;

        copado__JobTemplate__c templateWithPromotion = new copado__JobTemplate__c();
            templateWithPromotion.Name = 'MC_Retrieve_Action_With_Promotion';
            templateWithPromotion.copado__Version__c = 1;
            templateWithPromotion.copado__VolumeOptions__c = '[{ "name": "volumeSize", "value": "1" }, { "name": "volumeTTL", "value": "1440" },{ "name": "volumeEnabled", "value": "true" }]';
        insert templateWithPromotion;
        
        copado__JobExecution__c jobExecutionWithPromotion = new copado__JobExecution__c(
            copado__Promotion__c=promotion.id
        );
        insert jobExecutionWithPromotion;
        
        jobStepWithPromotion = new copado__JobStep__c(Name = 'stepWithAPromotion',
                copado__JobTemplate__c = templateWithPromotion.Id,
                copado__Type__c = 'Manual',
                copado__PipelineId__c = pipeline.Id,
	 	        copado__JobExecution__c=jobExecutionWithPromotion.Id);
        insert jobStepWithPromotion;

        copado__JobTemplate__c templateWithTest = new copado__JobTemplate__c();
            templateWithTest.Name = 'MC_Retrieve_Action_With_Test';
            templateWithTest.copado__Version__c = 1;
            templateWithTest.copado__VolumeOptions__c = '[{ "name": "volumeSize", "value": "1" }, { "name": "volumeTTL", "value": "1440" },{ "name": "volumeEnabled", "value": "true" }]';
        insert templateWithTest;
        
        copado__Test__c test = new copado__Test__c(
            copado__User_Story__c=userStoryWithBranch.Id
        );
        insert test;

        copado__JobExecution__c jobExecutionWithTest = new copado__JobExecution__c(copado__ParentRecord_Id__c=test.Id);
        insert jobExecutionWithTest;
        
        jobStepWithTest = new copado__JobStep__c(Name = 'stepWithoutAPromotion',
                copado__JobTemplate__c = templateWithTest.Id,
                copado__Type__c = 'Manual',
                copado__PipelineId__c = pipeline.Id,
                copado__JobExecution__c=jobExecutionWithTest.Id);
        insert jobStepWithTest;
    }
}