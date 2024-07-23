global with sharing class CalculateContext implements copado.ParameterExpressionCallable {
    global String execute(Id stepId) {
        Map<String, String> result = new Map<String, String>();
        Id userStoryId;
        copado__JobStep__c step = [SELECT Id, copado__JobExecution__c, copado__PipelineId__c
                                              FROM copado__JobStep__c
                                              WHERE Id = :stepId WITH USER_MODE];

        copado__JobExecution__c execution = [SELECT Id,
                                                    copado__ParentRecord_Id__c,
                                                    copado__UserStoryCommit__c,
                                                    copado__Promotion__c
                                              FROM copado__JobExecution__c
                                              WHERE Id = :step.copado__JobExecution__c WITH USER_MODE];

        if (!String.isEmpty(execution.copado__ParentRecord_Id__c)) {
            Id contextId = Id.valueOf(execution.copado__ParentRecord_Id__c);
            String sobjectName = contextId.getSobjectType().getDescribe().getName();

            // NOTE: is there any other case to handle?
            if (sobjectName == copado__Test__c.class.getName()) {
                copado__Test__c test = [SELECT Id, copado__User_Story__c
                                        FROM copado__Test__c
                                        WHERE Id = :contextId WITH USER_MODE];

                userStoryId = test.copado__User_Story__c;
            }
        } else if (!String.isEmpty(execution.copado__UserStoryCommit__c)) {
            copado__User_Story_Commit__c userCommit = [SELECT Id, copado__User_Story__c
                                                        FROM copado__User_Story_Commit__c
                                                        WHERE Id = :execution.copado__UserStoryCommit__c WITH USER_MODE];
            result.put('userStoryCommitId', userCommit.Id);
            userStoryId = userCommit.copado__User_Story__c;
        } else if (!String.isEmpty(execution.copado__Promotion__c)) {
            copado__Promotion__c promotion = [SELECT 
                                                    Id,
                                                    Name,
                                                    copado__Destination_Environment__c,
                                                    copado__Project__c,
                                                    copado__Project__r.copado__Deployment_Flow__c,
                                                    copado__Project__r.copado__Deployment_Flow__r.copado__Main_Branch__c
                                                FROM copado__Promotion__c
                                                WHERE Id = :execution.copado__Promotion__c WITH USER_MODE];
            // TODO: add context
            List<copado__Deployment_Flow_Step__c> flow = [SELECT copado__Branch__c
                                                    FROM copado__Deployment_Flow_Step__c
                                                    WHERE copado__Source_Environment__c = :promotion.copado__Destination_Environment__c
                                                    AND copado__Deployment_Flow__c = :promotion.copado__Project__r.copado__Deployment_Flow__c WITH USER_MODE];
            if (flow.size() > 0) { 
                result.put('baseBranch', flow.get(0).copado__Branch__c);
            } else {
                result.put('baseBranch', promotion.copado__Project__r.copado__Deployment_Flow__r.copado__Main_Branch__c);
            }

            result.put('promotionId', execution.copado__Promotion__c);
            result.put('branch', 'promotion/' + promotion.Name);
        }

        if (userStoryId != null) {
            copado__User_Story__c userStory = [SELECT Id, Name, copado__Base_Branch__c, copado__Project__r.copado__Deployment_Flow__r.copado__Main_Branch__c 
                                                FROM copado__User_Story__c
                                                WHERE Id = :userStoryId WITH USER_MODE];

            if (userStory.copado__Base_Branch__c != null && userStory.copado__Base_Branch__c != '') {
                result.put('baseBranch', userStory.copado__Base_Branch__c);
            } else {
                result.put('baseBranch', userStory.copado__Project__r.copado__Deployment_Flow__r.copado__Main_Branch__c);
            }

            result.put('userStoryId', userStory.Id);
            result.put('branch', 'feature/' + userStory.Name);
        }

        return JSON.serialize(result);
    }
}