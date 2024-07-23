public with sharing class ALM {
    /**
     * APEX LOGGING MANAGER
     * 
     * If there is an Error, or OVERRIDE_MODE is set or the User's Last Name field ends with '(<number>', we use this debugging library. No events are sent otherwise
     * - the Last Name trick is a quick way for non-admins to enable logging.
     * - if the last name of the user ends with '(1' '(2' or '(3', we send the logs via email.
     * - if the last name of the user ends with '(4' '(5' or '(6', we save the logs as Unscheduled Task for the user that triggered the action (a common object, does not obstruct usage)
     *     - This mode is more for development than for troubleshooting with the end-user, to avoid endless emails
     * 
     * - if misused the logs might contain sensitive information, so, beware of what you are logging.
     * - it extracts information from exceptions even after packaging! critical to troubleshoot.
     * 
     * RATIONALE:
     * Logging in Salesforce is difficult. The System Log is not ideal, unavalable in a Managed Packaged (except via Subscriber Login), and it slows down your app.
     * 
     * The activation of this feature is via the User's Last Name trick, so there is no additiona metadata, non-admins can update it, and it is fast and hopefully unobtrusive.
     * If it is not packaged, an Admin can also change the OVERRIDE_MODE variable
     * It is enocuraged to change the activation if a project allows for other mechanism (Hierarchical Custom Setting being ideal), though.
     *  
     * USAGE:
     * 
     * ALM.debug('getNewestOrder()', 'response='+response);
     * or
     * ALM.error('getNewestOrder()', 'there was an error parsing the response', e);
     * or even
     * ALM.log('DEBUG', 'getNewestOrder()', 'response='+response);
     * 
     * ... you can choose any log level, but TRACE/INFO/DEBUG/WARNING/ERROR are typical logging levels
     * 
     * This class is paired with the "ALM Send Email" Flow and the ALM__e Platform Event
     * 
     */

    // set this to: "(0": disable all "(1": ERROR-email "(2" INFO-email "(3": DEBUG-email "(4": ERROR-Task "(5" INFO-Task "(6": DEBUG-Task
    private final static String OVERRIDE_MODE = '';

    public static boolean debug(String section, Object line) { return log('DEBUG', section, line); }
    public static boolean info(String section, Object line) { return log('INFO', section, line); }
    public static boolean error(String section, Object line) { return log('ERROR', section, line); }
    public static boolean error(String section, Object line, Exception e) {
        return log('ERROR', section, (Object)(line+'\nLine='+e?.getLineNumber()+' Exception='+e+' // '+e?.getStackTraceString()));
    }

    public static boolean log(String level, String section, Object line) {
        String t = OVERRIDE_MODE==''? UserInfo.getLastName().right(2) :OVERRIDE_MODE;
        if( Test.isRunningTest() || (t!='(0' && (level=='ERROR'||'(1(2(3(4(5(6'.contains(t))) ) {
            if(level=='DEBUG' && !'(3(6'.contains(t)) { 
                return false;
            }
            String msg = (t+'); '+level + '; ' + section +'; ' + line + ('\n\nDMLRows:' + Limits.getDmlRows()+ ' DMLs:' + Limits.getDmlStatements()+ ' QueryRows:' + Limits.getQueryRows()+ ' LocatorRows:' + Limits.getQueryLocatorRows()+ ' Callouts:' + Limits.getCallouts()+ ' FutureCalls:' + Limits.getFutureCalls()+ ' CpuTime:' + Limits.getCpuTime()+ ' HeapSize:' + Limits.getHeapSize()+ ' Queries:' + Limits.getQueries()+ ' QueueableJobs:' + Limits.getQueueableJobs()+ ' ImmediateDML:' + Limits.getPublishImmediateDML()+ ' DailyStreamingApiEvents:' + OrgLimits.getMap().get('DailyStreamingApiEvents').getValue()+ ' RequestId:' + Request.getCurrent().getRequestId()+ ' Quiddity:' + Request.getCurrent().getQuiddity())).left(32768);
            Database.SaveResult[] results = EventBus.publish(new ALM__e[]{new ALM__e(Log__c=msg)});
            System.debug(results[0].isSuccess() ?msg : ('err: '+results[0].getErrors()+msg.left(4096) ));
            return results[0].isSuccess();
        }
        return false;
    }
}