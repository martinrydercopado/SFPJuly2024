trigger NewObjectJune11Trigger on NewObjectJune11__c (before insert) {
    for(NewObjectJune11__c newObj : Trigger.new) {
        if(newObj.Name != null) {
            newObj.Name = newObj.Name + ' - New Object Name';
        }
    }
}