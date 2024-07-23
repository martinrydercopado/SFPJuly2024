@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class EnvironmentCreate implements copado.JobExecutionCallback {

    // NOTE: never use Ids ... non-required ids are rejected because Flows send empty string instead of null
    @JsonAccess(serializable='always' deserializable='always')
    global class Request {
        @InvocableVariable(required=true)
        global Id environmentDefinitionId;

        @InvocableVariable
        global String fromBranch;

        @InvocableVariable
        global String createBranch;

        @InvocableVariable
        global String environmentPersonaId;

        @InvocableVariable
        global String[] environmentPersonaIds;

        @InvocableVariable
        global String newEnvironmentId;

        @InvocableVariable
        global String pipelineDestinationEnvId;

        @InvocableVariable
        global Boolean isForPooling = false;

        // only used on EnvironmentCreateBatch(), if isForPooling=true and the records are already created 
        @InvocableVariable
        global String environmentOrgId;

        // non-global (so, not externally visible) variables to serialize:

        public EnvironmentDefinition__c def;
        public Boolean skipCreateOrg = false;
        public Boolean skipDeployMetadata = false;
        public Boolean skipUpdatePipeline = false;
        public Boolean isPreexistingOrg = false;
        public String newOrgId; // Salesforce Org Id, for pre-existing, poled orgs
    }

    global class Response {
        @InvocableVariable
        global Id jobExecutionId;
        @InvocableVariable
        global Id environmentOrgId;
    }

    @InvocableMethod(category='Environment Manager')
    global static List <Response> run(List<Request> requests) {
        // NOTE: this is NOT bulkified. If needed be, call it in a Queueable, 1 request per transaction
        if(requests.size()>1) {
            throw new CalloutException('Invocable not bulkified');
        }
        Request request = requests[0];

        // NOTE: some fields are used in the callback and in the EnvironmentCreateSave class
        // NOTE: this should return only the available environment orgs
        request.def = [
            SELECT Id, 
                Name, 
                Status__c, 
                OrgType__c, 
                ExpirationDays__c,
                DefaultBranch__c,
                ParentEnvironment__c, 
                PipelineDestinationEnvId__c,
                DefinitionJson__c,
                PackageInstallationJson__c,
                Project__r.copado__Deployment_Flow__c, 
                Project__r.copado__Deployment_Flow__r.copado__Platform__c,
                JobTemplate__r.copado__ApiName__c,
                (SELECT Id, Status__c, Environment__r.copado__Org_ID__c FROM Environment_Orgs__r WHERE Status__c IN ('Available') ORDER By CreatedDate ASC LIMIT 1)
            FROM EnvironmentDefinition__c
            WHERE Id = : request.environmentDefinitionId
            WITH USER_MODE
            ];

        // Sanitize user input. It is critical for security. Id's are not necessary to sanitize
        request.def.Name = request.def.Name.replaceAll('[\'$]+', '');
        request.fromBranch = request.fromBranch?.replaceAll('[^a-zA-Z0-9_]+', '');
        request.createBranch = request.createBranch?.replaceAll('[^a-zA-Z0-9_]+', '');

        // calculate the values needed for the steps
        request.pipelineDestinationEnvId = request.def.PipelineDestinationEnvId__c;
        request.skipCreateOrg = String.isNotEmpty(request.newEnvironmentId);
        request.skipUpdatePipeline = String.isEmpty(request.pipelineDestinationEnvId) || String.isEmpty(request.createBranch);
        request.skipDeployMetadata = String.isEmpty(request.fromBranch);
        // NOTE: only 1 request can be handled. A limits problem queuing job executions
        request.environmentPersonaId = String.isEmpty(request.environmentPersonaId) 
            && request.environmentPersonaIds != null 
            && request.environmentPersonaIds.size()>0
            ?request.environmentPersonaIds[0]
            :request.environmentPersonaId;

        // when we are creating orgs for the future, we do not want them in the pipeline, yet. 
        // They lack authentication, and they are not in use
        if(request.isForPooling) {
            request.skipUpdatePipeline = true;
            request.skipCreateOrg = false;
        }else{
            // count the available environment orgs
            request.isPreexistingOrg = request.def.Environment_Orgs__r.size()>0;
            request.skipCreateOrg = request.isPreexistingOrg;
        }

        // Run some validations
        Boolean isAdmin = FeatureManagement.checkPermission('Environment_Manager_Admin');
        EnvironmentCommons.errorIf(!isAdmin && request.def.Status__c!='Ready', 'This Environment Definition is not ready for use (Its status is not "Ready").');
        EnvironmentCommons.errorIfInvalidJson(request.def.DefinitionJson__c, false, 'The Definition Json must be a valid JSON string for Salesforce Scratch Org / Sandbox');
        EnvironmentCommons.errorIfInvalidJson(request.def.PackageInstallationJson__c, true, 'The Package Installation Json field must be empty, or a valid JSON string as defined in the Environment Manager documentation');

        Integer hasSFDXAuthentication = [SELECT count() FROM copado__System_Property__c WHERE copado__API_Name__c='ENVIRONMENT_MANAGER_AUTH' AND copado__Environment__c = :request.def.ParentEnvironment__c];
        EnvironmentCommons.errorIf(hasSFDXAuthentication<1, 'The Parent Environment does not have the System Property ENVIRONMENT_MANAGER_AUTH set');

        // get or create the EnvironmentOrg record, it will be updated after org creation, and again in the callback
        Date expiration = (request.def.ExpirationDays__c!=null && request.def.ExpirationDays__c>0) 
            ?System.today().addDays(Integer.valueOf(request.def.ExpirationDays__c))
            :null;

        // TODO: this might not be concurrency safe?... the t.def.Environment_Orgs__r[0].Id might have been taken already
        EnvironmentOrg__c envOrg = new EnvironmentOrg__c(
            Name=request.def.Name,
            EnvironmentDefinition__c=request.def.Id,
            ExpirationDate__c = expiration,
            Status__c='Creating'
        );
        if(request.isForPooling) {
            envOrg.Id = request.environmentOrgId;
        }else if(request.isPreexistingOrg) {
            envOrg.Id = request.def.Environment_Orgs__r[0].Id;
            request.newOrgId = request.def.Environment_Orgs__r[0].Environment__r.copado__Org_ID__c;
        }else{
            envOrg.Environment__c = request.newEnvironmentId;
        }
        upsert as system envOrg;
        request.environmentOrgId = envOrg.Id;

        ALM.info('EnvironmentCreate.run()', 'def='+request.def.Id
            +' name='+request.def.Name
            +' environmentOrgId='+request.environmentOrgId
            +' isForPooling='+request.isForPooling
            +' isPreexistingOrg='+request.isPreexistingOrg);

        copado.CreateExecution.Request jobRequest = new copado.CreateExecution.Request();
        jobRequest.parentId = request.environmentDefinitionId;
        jobRequest.templateName = request.def.JobTemplate__r.copado__ApiName__c;
        jobRequest.pipelineId = request.def.Project__r.copado__Deployment_Flow__c;
        jobRequest.sourceId = request.def.ParentEnvironment__c;
        // NOTE: this is tipically null, in order to create a NEW environment
        jobRequest.destinationId = request.newEnvironmentId;
        jobRequest.callback = EnvironmentCreate.class.getName(); 
        jobRequest.runAfterInstantiation = true;
        // save the request for the steps/callback to use later
        jobRequest.dataJson = JSON.serialize(request);

        copado__JobExecution__c[] jobExecutions = copado.CreateExecution.execute(new copado.CreateExecution.Request[]{jobRequest});
        Response response = new Response();
        response.jobExecutionId = jobExecutions[0].Id;
        response.environmentOrgId = envOrg.Id;

        envOrg = new EnvironmentOrg__c(Id=envOrg.Id, LastJobExecutionId__c= jobExecutions[0].Id);
        update as system envOrg;

        // flag to never call a batch from another batch.
        if( !request.isForPooling ) {
            Boolean willCreateAUser = String.isNotEmpty(request.environmentPersonaId);
            EnvironmentCreateBatch.createOrgsInPool(request.environmentDefinitionId, request.isPreexistingOrg, willCreateAUser);
        }

        return new List<Response>{response};
    }

    // callback: called when the Job Template finishes, success or failure
    global void execute(copado__JobExecution__c job, String status) {
        // prepare the error message field, in case it is necessary
        job.copado__ErrorMessage__c = (String.isEmpty(job.copado__ErrorMessage__c) ?'' :job.copado__ErrorMessage__c);

        try{
            String transactionId = EnvironmentCommons.getTransactionIdFromJob(job);
            Request request = (Request) EnvironmentCommons.parseDataJson(job, Request.class);

            Boolean willCreateAUser = String.isNotEmpty(request.environmentPersonaId);

            EnvironmentOrg__c envOrg = new EnvironmentOrg__c(
                Id = request.environmentOrgId,
                Status__c = willCreateAUser ?'In Use' :'Available'
            );
            if(status != 'Successful') {
                envOrg.Status__c = 'Error';
                willCreateAUser= false;
            }
            update as system envOrg; // NOTE: we use system mode, because the running user should not have permissions

            if(willCreateAUser) {
                PersonaCreate.Request personaReq = new PersonaCreate.Request();
                personaReq.environmentPersonaId = request.environmentPersonaId;
                personaReq.environmentOrgId = envOrg.Id;
                personaReq.transactionId = transactionId;
                System.debug('about to call');
                PersonaCreate.Response[] resps =  PersonaCreate.run(new PersonaCreate.Request[]{personaReq});
                System.debug('resps='+resps);
            }
        }catch(Exception e) {
            System.debug('EnvironmentCreate.Callback error '+e+' '+e.getLineNumber()+' '+e.getStackTraceString());
            job.copado__ErrorMessage__c += '\n\nCallback Error: '+e+' line: '+e.getLineNumber();
        }
    }
}