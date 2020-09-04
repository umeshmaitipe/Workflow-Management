/*
*   This class contains reusable Case record creation methods that are needed for unit testing
*/
@IsTest
public class CaseTestDataFactory {

    /*
    *   Will create the requested number of cases related to the passed in Account record
    */
    public static List<Case> createCaseRecords(Account acct, Integer recordCount, Boolean insertIntoDB) {
        List<Case> caseRecordList = new List<Case>();
        for(Integer count = 0; count < recordCount; count++) {
            Case caseRec = new Case();
            caseRec.AccountId = acct.Id;
            caseRec.Subject = 'Test case ' + count;
            caseRec.Description = 'Test case ' + count;
            caseRec.status = 'New';
            caseRecordList.add(caseRec);
        }

        if(insertIntoDB) {
            insert caseRecordList;
        }

        return caseRecordList;
    }
}