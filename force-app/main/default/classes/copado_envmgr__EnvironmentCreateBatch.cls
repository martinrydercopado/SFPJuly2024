public with sharing class EnvironmentCreateBatch implements Database.Batchable<String>, Database.Stateful {

    private Id environmentDefinitionId;
    private String[] environmentOrgIds;

    public EnvironmentCreateBatch() {
    }

    public EnvironmentCreateBatch(Id environmentDefinitionId, EnvironmentOrg__c[] envOrgs) {
        this.environmentDefinitionId = environmentDefinitionId;
        // we create a list of Iterables. The value actually does not matter, just the lenght of the list
        this.environmentOrgIds = new String[]{};
        for(EnvironmentOrg__c envOrg : envOrgs) {
            environmentOrgIds.add(envOrg.Id);
        }
        System.debug('EnvironmentCreateBatch '+environmentOrgIds);
    }

    public static void createOrgsInPool(Id environmentDefinitionId, boolean isReusingOrg, boolean willCreateAUser) {
        // get the environment definition and get the count of the orgs that we should create
        // plus the orgs already created or in the process of creation
        EnvironmentDefinition__c def = [
            SELECT Name,
                DesiredAvailableOrgs__c,
                ExpirationDays__c,
                (SELECT Id, Status__c FROM Environment_Orgs__r WHERE Status__c IN ('Creating', 'Created', 'Available') ORDER By CreatedDate ASC LIMIT 1000)
            FROM EnvironmentDefinition__c
            WHERE Id = : environmentDefinitionId
            WITH USER_MODE
            ];

        // +1 becasue there will be a fresh org being created in EnvironmentCreate
        Integer desiredAvailableOrgs = Integer.valueOf(def.DesiredAvailableOrgs__c==null ?0 :def.DesiredAvailableOrgs__c) ;
        Integer diff = 1 + desiredAvailableOrgs
            - def.Environment_Orgs__r.size();

        ALM.debug('EnvironmentCreateBatch.createOrgsInPool()', 'def='+environmentDefinitionId+' name='+def.Name+' desired='+def.DesiredAvailableOrgs__c+' diff='+diff+' willCreateAUser='+willCreateAUser);

        if(desiredAvailableOrgs==0 || diff <= 0) {
            return; // there are no orgs to add.
        }

        EnvironmentOrg__c[] envOrgs = new EnvironmentOrg__c[]{};
        while(diff-->0) {
            EnvironmentOrg__c envOrg = new EnvironmentOrg__c(
                Name=def.Name,
                EnvironmentDefinition__c=def.Id,
                Status__c='Creating'
            );
            envOrgs.add(envOrg);
        }
        upsert as system envOrgs;

        Database.executeBatch( new EnvironmentCreateBatch(environmentDefinitionId, envOrgs), 1);
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        return this.environmentOrgIds;
    }

    public void execute(Database.BatchableContext info, String[] environmentOrgIds) {
        for(String environmentOrgId: environmentOrgIds) {
            EnvironmentCreate.Request req = new EnvironmentCreate.Request();
            req.isForPooling = true; // it must be set so it is not added to the pipeline and other tasks are not executed
            req.environmentDefinitionId = this.environmentDefinitionId;
            req.environmentOrgId = environmentOrgId;
            System.debug(req);
            EnvironmentCreate.Response[] resps =  EnvironmentCreate.run(new EnvironmentCreate.Request[]{req});
        }
    }

    public void finish(Database.BatchableContext info) {}
}