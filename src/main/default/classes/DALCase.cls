/*
*  Queries on the Case object and transformation of this object field values before passing on should be captured in this class 
*/
public without sharing class DALCase extends DALBase {
    public static final String EXTRACTION_STATUS_NEW = 'New'; 
    public static final String EXTRACTION_STATUS_PROCESSED = 'Processed'; 
    public static final String EXTRACTION_STATUS_ERROR = 'Error'; 

    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_STATUS_OPEN = 'Open';
    public static final String CASE_STATUS_CLOSED = 'Closed';

    public Schema.SObjectType getSObjectType(){
        return Case.sObjectType;
    }
    
    /*
    *   Will return a List of Cases matching a passed in list of statuses 
    */
    public List<Case> getCaseByStatuses(List<String> statusList) {
        String sqlStmt = String.format('SELECT {0} FROM {1} WHERE Status IN :statusList',
                                        new List<String>{getFieldListString(), getSObjectName()});

        return Database.query(sqlStmt); 
    }

    /*
    *   Will return a List of Cases matching a passed in list of statuses and with Extraction_Status__c field matching passed in value
    */
    public String getExtractionReadyCases(List<String> statusList, String extractionStatus) {
        String sqlStmt = String.format('SELECT {0} FROM {1} WHERE Status IN :statusList AND Extraction_Status__c = :extractionStatus',
                                        new List<String>{getFieldListString(), getSObjectName()});

        return sqlStmt; 
    }
}