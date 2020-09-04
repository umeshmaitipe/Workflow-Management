/*
*   Query all the Cases that are in Closed status and will do callouts for each case in batches of 100 (Scope)
*   The scope of 100 is selected because that is the current limit in number of callouts in a transaction
*   Will make the batch scope a configurable value through a List type Custom Setting
*/
public without sharing class ProcessClosedCaseBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
    private static final String SCHEDULED_JOB_NAME = 'Workflow Management Case Extract';
    private Workflow_Management_Case_Extract_Setting__c defaultSettings;

    /*
    *   Will use a QueryLocator since the Case records can be passed to the execution method without additional processing
    *   Also can query upto 50 million records
    */
    public Database.QueryLocator start(Database.BatchableContext BC){
        List<String> statusList = new List<String>{DALCase.CASE_STATUS_CLOSED};
        String extractionStatus = DALCase.EXTRACTION_STATUS_NEW;
        String query = ProcessClosedCaseBatchService.getExtractionReadyClosedCases(statusList, extractionStatus);
        return Database.getQueryLocator(query);
    }
 
    public void execute(Database.BatchableContext BC, List<SObject> caseList){
        if(caseList != null && !caseList.isEmpty()) {
            ProcessClosedCaseBatchService.invokeWorkflowManagementAPI(caseList);
        }
    }

    public void finish(Database.BatchableContext BC){
        //Can use the finish method to send out an email to relavent parties regarding how many records were successful and how many failed
     }

    //Implement Schedulable Interface methods
    public void execute(SchedulableContext sc) {
        this.defaultSettings = Workflow_Management_Case_Extract_Setting__c.getInstance('DEFAULT');
        Integer scope = 100;
        if(this.defaultSettings != null && this.defaultSettings.batch_scope__c != null) {
            scope = (defaultSettings.batch_scope__c).intValue();
        }
        Database.executeBatch(new ProcessClosedCaseBatch(), scope);
    }
}