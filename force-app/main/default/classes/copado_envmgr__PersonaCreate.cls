@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PersonaCreate implements copado.JobExecutionCallback {

    // NOTE: never use Ids ... non-required ids are rejected because Flows send empty string instead of null
    @JsonAccess(serializable='always' deserializable='always')
    global class Request {
        @InvocableVariable(required=true)
        global String environmentPersonaId;

        @InvocableVariable(required=true)
        global String environmentOrgId;

        @InvocableVariable
        global String transactionId;

        @InvocableVariable
        global String fromBranch;

        @InvocableVariable
        global String email;

        // non-global (so, not externally visible) variables to serialize:

        public String randomString;
        public String username;
        public EnvironmentPersona__c def;
        public EnvironmentOrg__c org;
        public Date expiration;
    }

    global class Response {
        @InvocableVariable
        global Id jobExecutionId;
        @InvocableVariable
        global Id envirionmentUserId;
    }

    @InvocableMethod(category='Environment Manager')
    global static List <Response> run(List<Request> requests) {
        // NOTE: this is NOT bulkified. If needed be, call it in a Queueable, 1 request per transaction
        if(requests.size()>1) {
            throw new CalloutException('Invocable not bulkified');
        }
        Request request = requests[0];

        // NOTE: some fields are used in the callback and in the EnvironmentCreateSave class
        request.def = [
            SELECT Id, Name, ExpirationDays__c, Username__c,
                JobTemplate__r.copado__ApiName__c, 
                EnvironmentDefinition__c,
                EnvironmentDefinition__r.OrgType__c,
                EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c,
                EnvironmentDefinition__r.ParentEnvironment__c
            FROM EnvironmentPersona__c
            WHERE Id = : request.environmentPersonaId
            WITH USER_MODE ];

        request.org = [
            SELECT Id, Environment__c, Status__c
            FROM EnvironmentOrg__c
            WHERE Id = : request.environmentOrgId
            WITH USER_MODE ];
    
        // Serialize the user's selections, setting default when applicable

        // Sanitize user input. It is critical for security. Id's are not necessary to sanitize
        request.fromBranch = request.fromBranch?.replaceAll('[^a-zA-Z0-9_]+', '');
        request.def.Username__c = request.def.Username__c?.replaceAll('[\'"]+', '');

        request.randomString = String.valueOf(10000+Integer.valueof((Math.random() * 89990)));
        request.username = request.def.Username__c.replaceAll('(?i)\\{!random\\}', request.randomString);
        request.email = String.isNotEmpty(request.email) ?request.email : UserInfo.getUserEmail();
        request.expiration = (request.def.ExpirationDays__c!=null && request.def.ExpirationDays__c>0) 
            ?System.today().addDays(Integer.valueOf(request.def.ExpirationDays__c))
            :null;

        // TODO: validate ? e.g. validate org status

        // "upsert" EnvironmentUser__c
        // If the property exists, we will ignore any change to avoid ownership issues. It is unlikely, but can happen when mocking the creation
        EnvironmentUser__c envUser = new EnvironmentUser__c(
            Name=request.username,
            EnvironmentOrg__c=request.org.Id,
            EnvironmentPersona__c=request.environmentPersonaId,
            ExpirationDate__c = request.expiration,
            Status__c='Creating'
        );
        upsertEnvironmentUserByUsername(envUser);

        copado.CreateExecution.Request jobRequest = new copado.CreateExecution.Request();
        jobRequest.parentId = request.environmentPersonaId;
        jobRequest.templateName = request.def.JobTemplate__r.copado__ApiName__c;
        jobRequest.pipelineId = request.def.EnvironmentDefinition__r.Project__r.copado__Deployment_Flow__c;
        jobRequest.sourceId = request.def.EnvironmentDefinition__r.ParentEnvironment__c;
        jobRequest.destinationId = request.org.Environment__c;
        jobRequest.callback = PersonaCreate.class.getName(); 
        jobRequest.runAfterInstantiation = true;
        jobRequest.transactionId = request.transactionId;
        // save the request for the steps/callback to use later
        jobRequest.dataJson = JSON.serialize(request);

        copado__JobExecution__c[] jobExecutions = copado.CreateExecution.execute(new copado.CreateExecution.Request[]{jobRequest});
        Response response = new Response();
        response.jobExecutionId = jobExecutions[0].Id;
        response.envirionmentUserId = envUser.Id;

        envUser = new EnvironmentUser__c(Id=envUser.Id, LastJobExecutionId__c= jobExecutions[0].Id);
        update as system envUser;

        return new List<Response>{response};
    }

    // callback: called when the Job Template finishes, success or failure
    global void execute(copado__JobExecution__c job, String status) {
        try{
            Request request = (Request) EnvironmentCommons.parseDataJson(job, Request.class);

            // "upsert" the Credential
            copado__Org__c credential = new copado__Org__c(
                Name=request.username,
                copado__Username__c=request.username,
                copado__Org_Type__c=request.def.EnvironmentDefinition__r.OrgType__c,
                copado__Environment__c=request.org.Environment__c
            );
            upsertCredentialByUsername(credential);

            // "upsert" EnvironmentUser__c
            // If the property exists, we will ignore any change to avoid ownership issues. It is unlikely, but can happen when mocking the creation
            EnvironmentUser__c envUser = new EnvironmentUser__c(
                Name=request.username,
                EnvironmentOrg__c=request.org.Id,
                EnvironmentPersona__c=request.def.Id,
                ExpirationDate__c = request.expiration,
                Status__c='In Use',
                Credential__c = credential.Id
            );
            if(status != 'Successful') {
                envUser.Status__c = 'Error';
            }
            upsertEnvironmentUserByUsername(envUser);

            if(status == 'Successful') {
                // Mark the org as in use.
                update as system new EnvironmentOrg__c(Id=request.environmentOrgId, Status__c='In Use');
            }
        }catch(Exception e) {
            System.debug('PersonaCreate.Callback error '+e+' '+e.getLineNumber()+' '+e.getStackTraceString());
            job.copado__ErrorMessage__c += '\n\nCallback Error: '+e+' line: '+e.getLineNumber();
        }
    }

    private static void upsertEnvironmentUserByUsername(EnvironmentUser__c user) {
        for(EnvironmentUser__c temp : [SELECT Id FROM EnvironmentUser__c WHERE Name=:user.Name WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1]) {
            user.Id = temp.Id;
        }
        upsert as system user;
    }

    private static void upsertCredentialByUsername(copado__Org__c credential) {
        for(copado__Org__c temp : [SELECT Id FROM copado__Org__c WHERE copado__Username__c=:credential.Name WITH SECURITY_ENFORCED LIMIT 1]) {
            credential.Id = temp.Id;
        }
        upsert as system credential;
    }
}