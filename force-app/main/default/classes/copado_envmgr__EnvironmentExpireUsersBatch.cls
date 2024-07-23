global with sharing class EnvironmentExpireUsersBatch implements Database.Batchable<SObject>, copado.JobExecutionCallback {

    @InvocableMethod(category='Environment Manager')
    global static void run() {
        Database.executeBatch( new EnvironmentExpireUsersBatch(), 1);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,
            EnvironmentPersona__c,
            EnvironmentPersona__r.DeleteJobTemplate__r.copado__ApiName__c,
            EnvironmentOrg__r.Environment__c,
            EnvironmentOrg__r.EnvironmentDefinition__r.ParentEnvironment__c,
            EnvironmentOrg__r.EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c
            FROM EnvironmentUser__c
            WHERE isExpired__c=true 
            AND Status__c!='Deleted' 
            AND EnvironmentPersona__r.DeleteJobTemplate__c != ''
            ORDER BY CreatedDate DESC LIMIT 1000]);
    }

    public void execute(Database.BatchableContext info, EnvironmentUser__c[] users) {
        System.debug('execute '+users);
        copado.CreateExecution.Request[] jobRequests =  new copado.CreateExecution.Request[]{};
        for(EnvironmentUser__c user: users) {
            copado.CreateExecution.Request jobRequest = new copado.CreateExecution.Request();
            jobRequest.parentId = user.Id;
            jobRequest.destinationId = user.EnvironmentOrg__r.Environment__c;
            jobRequest.pipelineId = user.EnvironmentOrg__r.EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c;
            jobRequest.sourceId = user.EnvironmentOrg__r.EnvironmentDefinition__r.ParentEnvironment__c;
            jobRequest.templateName = user.EnvironmentPersona__r.DeleteJobTemplate__r.copado__ApiName__c;
            jobRequest.callback = EnvironmentExpireUsersBatch.class.getName(); 
            jobRequest.runAfterInstantiation = true;
            jobRequests.add(jobRequest);
        }
        copado__JobExecution__c[] jobExecutions = copado.CreateExecution.execute(jobRequests);

        EnvironmentUser__c[] updates = new EnvironmentUser__c[]{};
        for(integer i=0 ; i < users.size() ; i++ ) {
            updates.add(new EnvironmentUser__c(Id=users[i].Id, LastJobExecutionId__c=jobExecutions[i].Id));
        }
        update as system updates;
    }

    public void finish(Database.BatchableContext info) {}

    // callback: called when the Job Template finishes, success or failure
    global void execute(copado__JobExecution__c job, String status) {
        System.debug('callback '+job);
        // query again, because the job engine does not specify which fields are queried
        job = [SELECT copado__ParentId__c FROM copado__JobExecution__c WHERE Id = :job.Id WITH SYSTEM_MODE];
        EnvironmentUser__c envUser = new EnvironmentUser__c(
            Id = job.copado__ParentId__c
        );

        envUser.Status__c = status != 'Successful' ?'Error' :'Deleted';
        update as system envUser;
    }
}