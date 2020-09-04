@isTest
public class DALCaseTest {

    @testSetup
    static void initializeData(){
        List<Account> accountRecords = AccountTestDataFactory.createAccountRecords('Individual Customer', 1, true);        
    }

    @isTest
    static void getCaseByStatusesTest() {
        Account acct = [SELECT Id, Name FROM Account LIMIT 1];
        System.assert(acct != null);

        List<Case> caseList = CaseTestDataFactory.createCaseRecords(acct, 2, false);
        System.assertEquals(2, caseList.size(), 'Error: incorrect number of case records');
        Case caseRecord1 = caseList.get(0);
        caseRecord1.Status = DALCase.CASE_STATUS_NEW;

        Case caseRecord2 = caseList.get(1);
        caseRecord2.Status = DALCase.CASE_STATUS_OPEN;

        insert caseList;

        Test.startTest();
            DalCase caseDAL = new DALCase();
            List<Case> newCaseList = caseDAL.getCaseByStatuses(new List<String>{DALCase.CASE_STATUS_NEW});
            System.assertEquals(1, newCaseList.size(), 'Error: incorrect number of case records with New status');
        Test.stopTest();
    }

    @isTest
    static void getExtractionReadyCasesTest() {
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
            DalCase caseDAL = new DALCase();
            List<String> statusList = new List<String>{DALCase.CASE_STATUS_CLOSED};
            String extractionStatus = DALCase.EXTRACTION_STATUS_NEW;
            String queryStr = caseDAL.getExtractionReadyCases(statusList, extractionStatus);
            List<Case> extractionReadyCaseList = Database.query(queryStr);
            System.assertEquals(1, extractionReadyCaseList.size(), 'Error: incorrect number of extraction ready case records retrieved');
        Test.stopTest();
    }
}