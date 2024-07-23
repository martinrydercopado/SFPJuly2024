@SuppressWarnings('PMD.AvoidGlobalModifier')
// called from the org creation function to store the newly created Org as soon as possible, before the 2nd step
// NOTE: without sharing because a regular User may not have permisisons for things like copado__System_Property__c after Copado Deployer v21.x
@RestResource(urlMapping='/environmentsave/*')
global without sharing class EnvironmentSaveActions {

    @HttpPost
    global static void save() {
        if( RestContext.request.params.get('action') == 'saveOrg') {
            String jobExecutionId = RestContext.request.params.get('jobExecutionId');
            String newOrgId = RestContext.request.params.get('newOrgId');
            newOrgId = Id.valueOf(newOrgId);
            String sfdxUrl = RestContext.request.params.get('sfdxUrl');
            String environmentOrgId = RestContext.request.params.get('environmentOrgId');
            String environmentDefinitionId = RestContext.request.params.get('environmentDefinitionId');

            // this should never happen, unless the Functions are incorrect, that's why we validate using assertions
            Assert.isTrue(String.isNotEmpty(jobExecutionId), 'jobExecutionId: required value');
            Assert.isTrue(String.isNotEmpty(environmentOrgId), 'environmentOrgId: required value');
            Assert.isTrue(String.isNotEmpty(environmentDefinitionId), 'environmentDefinitionId: required value');

            ALM.info('EnvironmentSaveActions.save()', 'jobExecutionId='+jobExecutionId
                +' environmentOrgId='+environmentOrgId
                +' environmentDefinitionId='+environmentDefinitionId
                +' sfdxUrl='+String.isNotEmpty(sfdxUrl)
                );

            copado__JobExecution__c job = [SELECT copado__DataJson__c FROM copado__JobExecution__c WHERE Id = :jobExecutionId WITH SECURITY_ENFORCED LIMIT 1];
            EnvironmentCreate.Request request = (EnvironmentCreate.Request) EnvironmentCommons.parseDataJson(job, EnvironmentCreate.Request.class);

            // NOTE: most of the DML are in system mode, because the running user should not have permissions to do DML's on those objects
            copado__Environment__c env = new copado__Environment__c(
                Name=(request.def.Name+' '+newOrgId).left(80),
                copado__Type__c=request.def.OrgType__c,
                copado__Platform__c='SFDX',
                copado__Org_ID__c=newOrgId,
                copado__Last_Refresh_Date__c = System.today()
                );
            upsert as system env copado__Org_ID__c;

            EnvironmentOrg__c org = new EnvironmentOrg__c(
                Id=String.isEmpty(environmentOrgId) || environmentOrgId=='testing-only' ?null :environmentOrgId,
                Name=(request.def.Name+' '+newOrgId).left(80),
                Environment__c=env.Id,
                EnvironmentDefinition__c=environmentDefinitionId,
                Status__c='Created',
                OrgId__c=newOrgId
            );
            // NOTE: an error can happen when the end-user is in TESTING mode
            try{
                upsert as system org;
            }catch(System.DmlException e) {
                System.debug(e);
                // if the error is duplicated OrgId__c value, just remove it.
                if(e.getMessage().contains('OrgId__c')) {
                    org.OrgId__c = null;
                    upsert as system org;
                }else{
                    throw e;
                }
            }

            // "upsert" the system property.
            // If the property exists, we will ignore any change to avoid ownership issues. It is unlikely, but can happen when mocking the creation
            copado__System_Property__c s = new copado__System_Property__c(Name='SfdxUrl', copado__API_Name__c='SfdxUrl', 
                copado__Environment__c=env.Id, copado__Is_Sensitive__c=true);
            String uid = env.Id + '-' + s.Name;
            boolean notFound = [SELECT Id FROM copado__System_Property__c WHERE copado__UID__c=:uid WITH USER_MODE LIMIT 1].isEmpty();
            if(notFound) {
                s.copado__Value__c=sfdxUrl;
                upsert as system s;
            }

            // update the Job Template with the Destination Env. Following Steps will have a Destination
            update as system new copado__JobExecution__c(Id=jobExecutionId, 
                copado__Destination__c=env.Id
                );
        }
    }
}