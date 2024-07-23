global with sharing class EnvironmentExpireOrgsBatch implements Database.Batchable<SObject>, copado.JobExecutionCallback {

    @InvocableMethod(category='Environment Manager')
    global static void run() {
        Database.executeBatch( new EnvironmentExpireOrgsBatch(), 1);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('starting....');
        System.debug([SELECT Id,
        EnvironmentDefinition__c,
        EnvironmentDefinition__r.DeleteJobTemplate__r.copado__ApiName__c,
        Environment__c,
        EnvironmentDefinition__r.ParentEnvironment__c,
        EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c
        FROM EnvironmentOrg__c
        WHERE isExpired__c=true 
        AND Status__c!='Deleted' 
        AND EnvironmentDefinition__r.DeleteJobTemplate__c != ''
        AND Environment__c != ''
        ORDER BY CreatedDate DESC LIMIT 1000]);

        return Database.getQueryLocator([SELECT Id,
            EnvironmentDefinition__c,
            EnvironmentDefinition__r.DeleteJobTemplate__r.copado__ApiName__c,
            Environment__c,
            EnvironmentDefinition__r.ParentEnvironment__c,
            EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c
            FROM EnvironmentOrg__c
            WHERE isExpired__c=true 
            AND Status__c!='Deleted' 
            AND EnvironmentDefinition__r.DeleteJobTemplate__c != ''
            AND Environment__c != ''
            ORDER BY CreatedDate DESC LIMIT 1000]);
    }

    public void execute(Database.BatchableContext info, EnvironmentOrg__c[] orgs) {
        copado.CreateExecution.Request[] jobRequests =  new copado.CreateExecution.Request[]{};
        for(EnvironmentOrg__c org: orgs) {
            copado.CreateExecution.Request jobRequest = new copado.CreateExecution.Request();
            jobRequest.parentId = org.Id;
            jobRequest.pipelineId = org.EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c;
            jobRequest.sourceId = org.EnvironmentDefinition__r.ParentEnvironment__c;
            jobRequest.destinationId = org.Environment__c;
            jobRequest.templateName = org.EnvironmentDefinition__r.DeleteJobTemplate__r.copado__ApiName__c;
            jobRequest.callback = EnvironmentExpireOrgsBatch.class.getName(); 
            jobRequest.runAfterInstantiation = true;
            jobRequests.add(jobRequest);
            System.debug(jobRequest);
        }
        copado__JobExecution__c[] jobExecutions = copado.CreateExecution.execute(jobRequests);

        EnvironmentOrg__c[] updates = new EnvironmentOrg__c[]{};
        for(integer i=0 ; i < orgs.size() ; i++ ) {
            updates.add(new EnvironmentOrg__c(Id=orgs[i].Id, LastJobExecutionId__c=jobExecutions[i].Id));
        }
        update as system updates;
    }

    public void finish(Database.BatchableContext info) {}

    // callback: called when the Job Template finishes, success or failure
    global void execute(copado__JobExecution__c job, String status) {
        ALM.debug('EnvironmentExpireOrgsBatch.jobCallback()', 'def='+job.copado__ParentId__c
            +' jobStatus='+status);

        // query again, because the job engine does not specify which fields are queried
        job = [SELECT copado__ParentId__c FROM copado__JobExecution__c WHERE Id = :job.Id WITH SYSTEM_MODE];
        EnvironmentOrg__c envOrg = new EnvironmentOrg__c(
            Id = job.copado__ParentId__c
        );
        envOrg.Status__c = status != 'Successful' ?'Error' :'Deleted';
        update as system envOrg; // NOTE: we use system mode, because the running user should not have permissions

        // TODO: We should call the pool regeneration only in the last item... we are calling it too much here
        envOrg = [SELECT EnvironmentDefinition__c FROM EnvironmentOrg__c WHERE Id = :job.copado__ParentId__c WITH SYSTEM_MODE LIMIT 1];
        EnvironmentCreateBatch.createOrgsInPool(envOrg.EnvironmentDefinition__c, false, false);
    }
}