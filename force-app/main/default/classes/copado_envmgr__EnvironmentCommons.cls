@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class EnvironmentCommons {

    public static String getTransactionIdFromJob(copado__JobExecution__c job) {
        String transactionId = '';
        if(String.isNotEmpty(job.copado__VolumeOptions__c)) {
            try{
                List<Object> tmp = (List<Object>)JSON.deserializeUntyped(job.copado__VolumeOptions__c);
                for(Object t : tmp) {
                    if( (String)((Map<String, Object>)t).get('name') == 'transactionId') {
                        transactionId = (String)((Map<String, Object>)t).get('value');
                    }
                }
            }catch(Exception e) {
                throw new AppException('Error: parsing copado__VolumeOptions__c: '+e.getMessage()+' '+job.copado__VolumeOptions__c);
            }
        }
        return transactionId;
    }

    public static Object parseDataJson(copado__JobExecution__c job, Type klass) {
        System.debug('job.copado__DataJson__c='+job.copado__DataJson__c);
        try{
            Object o = JSON.deserialize(job.copado__DataJson__c, klass);
            System.debug(o);
            return o;
        }catch(Exception e) {
            throw new AppException('Error: parsing copado__DataJson__c: '+e.getMessage()+' '+job.copado__DataJson__c);
        }
    }

    public static Object errorIfInvalidJson(String jsonString, boolean allowEmpty, String errorMessage) {
        if(allowEmpty && String.isBlank(jsonString)) {
            return null;
        }
        try{
            Object o = JSON.deserializeUntyped(jsonString);
            return o;
        }catch(Exception e) {
            throw new AppException(errorMessage);
        }
    }

    public static void errorIf(Boolean cond, String errorMessage) {
        if(cond) {
            throw new AppException(errorMessage);
        }
    }

    global with sharing class AppException extends Exception {}
}