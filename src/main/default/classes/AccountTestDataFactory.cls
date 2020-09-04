/*
*   This class contains reusable Account record creation methods that are needed for unit testing
*/
@IsTest
public class AccountTestDataFactory {

    /*
    *   Will create the requested number of Account record for the specified RecordType
    */
    public static List<Account> createAccountRecords(String recordType, Integer recordCount, Boolean insertIntoDB) {
        List<Account> accountRecordList = new List<Account>();
        for(Integer count = 0; count < recordCount; count++) {
            Account accountRec = new Account();
            accountRec.Name = 'Test Account ' + count;
            accountRec.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
            accountRecordList.add(accountRec);
        }

        if(insertIntoDB) {
            insert accountRecordList;
        }

        return accountRecordList;
    }
}