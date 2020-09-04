@isTest
public class ProcessClosedCaseBatchTest {

    @testSetup
    static void initializeData(){
        Workflow_Management_Case_Extract_Setting__c defaultSettings = new Workflow_Management_Case_Extract_Setting__c();
        defaultSettings.Name = 'DEFAULT';
        defaultSettings.base_url__c = 'http://mockEndpoint';
        defaultSettings.request_type__c = 'Post';
        defaultSettings.timeout__c = 5000;
        defaultSettings.content_type__c = 'application/json';
        insert defaultSettings;

        List<Account> accountRecords = AccountTestDataFactory.createAccountRecords('Individual Customer', 1, true);        
    }

    @isTest
    static void executeBatch_successTest() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 100, false);
        System.assertEquals(100, caseList.size(), 'Error: incorrect number of case records');
        for(Case caseRecord : caseList) {
            caseRecord.Status = DALCase.CASE_STATUS_CLOSED;
            caseRecord.Extraction_Status__c = DALCase.EXTRACTION_STATUS_NEW;
        }
        insert caseList;

        //WMP_successMockResponse Static Resource will contain: {"success":true,"secretKey":"212"}
        StaticResourceCalloutMock successMock = new StaticResourceCalloutMock();
        successMock.setStaticResource('WMP_successMockResponse');
        successMock.setStatusCode(200);
        successMock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, successMock);
        Test.startTest();
            ProcessClosedCaseBatch processBatch = new ProcessClosedCaseBatch();
            Database.executeBatch(processBatch);
        Test.stopTest();

        DALCase caseDAL = new DALCase();
        List<String> validStatus = new List<String>{DALCase.CASE_STATUS_CLOSED};
        List<Case> processededCaseList = new List<Case>(caseDAL.getCaseByStatuses(validStatus));

        for(Case processedCase : processededCaseList) {
            System.assertEquals(DALCase.EXTRACTION_STATUS_PROCESSED, processedCase.Extraction_Status__c, 'Error: incorrect Extraction Status on Case record');    
        }
    }

    @isTest
    static void executeBatch_errorTest() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 100, false);
        System.assertEquals(100, caseList.size(), 'Error: incorrect number of case records');
        for(Case caseRecord : caseList) {
            caseRecord.Status = DALCase.CASE_STATUS_CLOSED;
            caseRecord.Extraction_Status__c = DALCase.EXTRACTION_STATUS_NEW;
        }
        insert caseList;

        //WMP_errorMockResponse Static Resource will contain: {"success":false,"error":"error occured"}
        StaticResourceCalloutMock errorMock = new StaticResourceCalloutMock();
        errorMock.setStaticResource('WMP_errorMockResponse');
        errorMock.setStatusCode(500);
        errorMock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, errorMock);
        Test.startTest();
            ProcessClosedCaseBatch processBatch = new ProcessClosedCaseBatch();
            Database.executeBatch(processBatch);
        Test.stopTest();        

        DALCase caseDAL = new DALCase();
        List<String> validStatus = new List<String>{DALCase.CASE_STATUS_CLOSED};
        List<Case> processededCaseList = new List<Case>(caseDAL.getCaseByStatuses(validStatus));

        for(Case processedCase : processededCaseList) {
            System.assertEquals(DALCase.EXTRACTION_STATUS_ERROR, processedCase.Extraction_Status__c, 'Error: incorrect Extraction Status on Case record');    
        }
    }
}