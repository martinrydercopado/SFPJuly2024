@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class EnvironmentFlowActions {

    @JsonAccess(serializable='always' deserializable='always')
    global class Request {
        @InvocableVariable(required=true)
        global String action;

        @InvocableVariable
        global Id environmentDefinitionId;
    }

    global class Response {
        @InvocableVariable
        global copado__Environment__c[] pipelineEnvironments;

        @InvocableVariable
        global EnvironmentPersona__c[] personas;
    }

    @InvocableMethod
    global static List <Response> run(List<Request> requests) {
        // NOTE: this is NOT bulkified, to speed up implementation
        if(requests.size()>1) {
            throw new CalloutException('Invocable not bulkified');
        }
        Request req = requests[0];
        Response resp = new Response();
        System.debug(req);

        if(req.action == 'EnvironmentCreate') {
            EnvironmentDefinition__c envDef = [SELECT 
                    Project__r.copado__Deployment_Flow__c,
                    (SELECT Id, Name, Username__c, ExpirationDays__c FROM Environment_Personas__r ORDER BY Name)
                FROM EnvironmentDefinition__c 
                WHERE Id = :req.environmentDefinitionId 
                WITH USER_MODE];

            resp.personas = envDef.Environment_Personas__r;
            resp.pipelineEnvironments = [SELECT Id, Name FROM copado__Environment__c WHERE Id in 
                (SELECT copado__Destination_Environment__c FROM copado__Deployment_Flow_Step__c 
                WHERE copado__Deployment_Flow__c = :envDef.Project__r.copado__Deployment_Flow__c) WITH USER_MODE ORDER BY Name];

        }else if(req.action == 'EnvironmentUserCreate') {
            EnvironmentDefinition__c envDef = [SELECT 
                    Project__r.copado__Deployment_Flow__c,
                    (SELECT Id, Name, Username__c, ExpirationDays__c FROM Environment_Personas__r ORDER BY Name)
                FROM EnvironmentDefinition__c 
                WHERE Id = :req.environmentDefinitionId 
                WITH USER_MODE];

            resp.personas = envDef.Environment_Personas__r;
        }

        return new Response[]{resp};
    }

}