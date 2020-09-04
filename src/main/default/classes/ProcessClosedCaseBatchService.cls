/*
*   Moving the methods that support the data querying and subsequent processing into a service class will support code reusability 
*/
public inherited sharing class ProcessClosedCaseBatchService {

    @TestVisible
    private static Integer retryCounter = 0;

    public static String getExtractionReadyClosedCases(List<String> validStatusList, String extractionStatus) {
        DALCase caseDAL = new DALCase();
        return caseDAL.getExtractionReadyCases(validStatusList, extractionStatus);
    }

    /*
    *   Will trigger a Http callout to the Workflow Management Platform for each passed in Case. 
    *   Will build configurable capability to retrigger a failed callout
    *   If a individual callout is failing then will capture that Case record as an errored one and will continue with processing the rest 
    */
    public static void invokeWorkflowManagementAPI(List<SObject> caseList) {
        for(SObject obj : caseList) {
            Case caseRecord = (Case) obj;
            retryCounter = 0;
            invokeWorkflowManagementAPIForIndividualCase(caseRecord);            
        }

        update caseList;
    }

    /*
    *   Authentication between Salesforce and the external platform that host the Workflow Management API can be done through OAuth 
    *   by setting a Connected App in the external platform and sharing the Client token and secret 
    *   Store the Endpoint URL, Http method and Client Id and Secret in the list type custom setting called: Workflow_Management_Case_Extract_Setting__c 
    */
    @TestVisible
    public static void invokeWorkflowManagementAPIForIndividualCase(Case caseRecord) {
        Workflow_Management_Case_Extract_Setting__c defaultSettings = Workflow_Management_Case_Extract_Setting__c.getInstance('DEFAULT');
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(defaultSettings.base_url__c); 
            request.setMethod(defaultSettings.request_type__c);//POST
            request.setTimeout((defaultSettings.timeout__c).intValue());
            request.setHeader('Content-Type', defaultSettings.content_type__c);
            
            WorkflowManagementRequest requestBody = new WorkflowManagementRequest();
            requestBody.id = caseRecord.Id;
            requestBody.agentid = caseRecord.closedBy__c;
            String requestPayload = JSON.serialize(requestBody,true);
            request.setBody(requestPayload);
            System.debug('RequestPayload: ' + requestPayload);
        
            HttpResponse httpResponse = http.send(request);
            String response = httpResponse.getBody();
            System.debug('Response: ' + response);
            //Parse the response 
            if(String.isNotBlank(response)) {
                WorkflowManagementResponse responseBody = WorkflowManagementResponse.parse(response);
                System.debug('responseBody: ' + responseBody);
                if(responseBody.success) {
                    caseRecord.Extraction_Status__c = DALCase.EXTRACTION_STATUS_PROCESSED;
                    if(String.isBlank(responseBody.secretKey)) {
                        throw new CustomException('Missing Secret Key');
                    }
                    else {
                        caseRecord.secretKey__c = responseBody.secretKey;
                    }
                }
                else {//Error scenario
                    caseRecord.Extraction_STatus__c = DALCase.EXTRACTION_STATUS_ERROR;
                    caseRecord.errorMessage__c = responseBody.error;
                }
            }
        }
        catch(System.CalloutException ex) {
            //In case of a CalloutException, if the configured settings supports it will do retries
            if(defaultSettings.max_retry_Count__c != null && defaultSettings.max_retry_Count__c > retryCounter) {
                invokeWorkflowManagementAPIForIndividualCase(caseRecord);
                retryCounter++;
            }
            else {
                throw ex;
            }
        }
        catch(Exception ex) {
            caseRecord.Extraction_Status__c = DALCase.EXTRACTION_STATUS_ERROR;
            //In additiona to setting the Extraction_Status__c value, log the error accordingly using a logging framework
        }
    }        
}