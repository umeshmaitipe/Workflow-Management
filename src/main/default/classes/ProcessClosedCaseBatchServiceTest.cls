@isTest
public class ProcessClosedCaseBatchServiceTest {

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
    static void getExtractionReadyClosedCasesTest() {
        List<String> statusList = new List<String>{DALCase.CASE_STATUS_CLOSED};
        String extractionStatus = DALCase.EXTRACTION_STATUS_NEW;
        
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 3, false);
        System.assertEquals(3, caseList.size(), 'Error: incorrect number of case records');
        Case caseRecord1 = caseList.get(0);
        caseRecord1.Status = DALCase.CASE_STATUS_NEW;
        caseRecord1.Extraction_Status__c = DALCase.EXTRACTION_STATUS_NEW;

        Case caseRecord2 = caseList.get(1);
        caseRecord2.Status = DALCase.CASE_STATUS_CLOSED;
        caseRecord2.Extraction_Status__c = DALCase.EXTRACTION_STATUS_PROCESSED;

        Case caseRecord3 = caseList.get(2);
        caseRecord3.Status = DALCase.CASE_STATUS_CLOSED;
        caseRecord3.Extraction_Status__c = DALCase.EXTRACTION_STATUS_NEW;

        insert caseList;

        Test.startTest();
        	String queryStr = ProcessClosedCaseBatchService.getExtractionReadyClosedCases(statusList, extractionStatus);
            List<Case> extractionReadyCaseList = Database.query(queryStr);
            System.assertEquals(1, extractionReadyCaseList.size(), 'Error: incorrect number of extraction ready case records retrieved');
        Test.stopTest();   
    }
    
    /*
    *   Will use Static Resources to capture the Success response
    */
    @isTest
    static void invokeWorkflowManagementAPIForIndividualCase_SuccessfulCalloutTest() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 1, false);
        System.assertEquals(1, caseList.size(), 'Error: incorrect number of case records');
        Case caseRecord = caseList.get(0);
        caseRecord.Status = DALCase.CASE_STATUS_CLOSED;
        caseRecord.Extraction_Status__c = DALCase.EXTRACTION_STATUS_NEW;
        caseRecord.closedBy__c = UserInfo.getUserId(); 
        insert caseRecord;

        //WMP_successMockResponse Static Resource will contain: {"success":true,"secretKey":"212"}
        StaticResourceCalloutMock successMock = new StaticResourceCalloutMock();
        successMock.setStaticResource('WMP_successMockResponse');
        successMock.setStatusCode(200);
        successMock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, successMock);
        Test.startTest();
            ProcessClosedCaseBatchService.invokeWorkflowManagementAPIForIndividualCase(caseRecord);   
        	System.debug('caseRecord: ' + caseRecord);
            System.assertEquals(0, ProcessClosedCaseBatchService.retryCounter, 'Error: incorrect value in retry counter');
            System.assertEquals('212', caseRecord.secretKey__c, 'Error: Case record not capturing Secret Key');
            System.assertEquals(DALCase.EXTRACTION_STATUS_PROCESSED, caseRecord.Extraction_Status__c, 'Error: incorrect Extraction Status on Case record');
        Test.stopTest();        
    }

    /*
    *   Will use Static Resources to capture the Error response
    */
    @isTest
    static void invokeWorkflowManagementAPIForIndividualCase_ErrorCalloutTest() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 1, false);
        System.assertEquals(1, caseList.size(), 'Error: incorrect number of case records');
        Case caseRecord = caseList.get(0);

        //WMP_errorMockResponse Static Resource will contain: {"success":false,"error":"error occured"}
        StaticResourceCalloutMock errorMock = new StaticResourceCalloutMock();
        errorMock.setStaticResource('WMP_errorMockResponse');
        errorMock.setStatusCode(500);
        errorMock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, errorMock);
        Test.startTest();
            ProcessClosedCaseBatchService.invokeWorkflowManagementAPIForIndividualCase(caseRecord);
            System.assert(String.isBlank(caseRecord.secretKey__c), 'Error: Secret key captured on failed callout');
            System.assertEquals(0, ProcessClosedCaseBatchService.retryCounter, 'Error: incorrect value in retry counter');
            System.assertEquals('error occured', caseRecord.errorMessage__c, 'Error: Case record not capturing error message');
            System.assertEquals(DALCase.EXTRACTION_STATUS_ERROR, caseRecord.Extraction_Status__c, 'Error: incorrect Extraction Status on Case record');
        Test.stopTest();        
    }

    @isTest
    static void invokeWorkflowManagementAPITestTest() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 10, false);
        System.assertEquals(10, caseList.size(), 'Error: incorrect number of case records');
        for(Case caseRecord : caseList) {
            caseRecord.Status = DALCase.CASE_STATUS_CLOSED;
            caseRecord.Extraction_Status__c = DALCase.EXTRACTION_STATUS_NEW;
            caseRecord.closedBy__c = UserInfo.getUserId(); 
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
            ProcessClosedCaseBatchService.invokeWorkflowManagementAPI(caseList);

            //Requery the case record details:
            DALCase caseDAL = new DALCase();
            List<String> validStatus = new List<String>{DALCase.CASE_STATUS_CLOSED};
            List<Case> processededCaseList = new List<Case>(caseDAL.getCaseByStatuses(validStatus));
            System.assertEquals(0, ProcessClosedCaseBatchService.retryCounter, 'Error: incorrect value in retry counter');

            for(Case processededCase : processededCaseList) {
                System.assertEquals('212', processededCase.secretKey__c, 'Error: Case record not capturing Secret Key');
                System.assertEquals(DALCase.EXTRACTION_STATUS_PROCESSED, processededCase.Extraction_Status__c, 'Error: incorrect Extraction Status on Case record');
            }
        Test.stopTest();        
    }
}