public class WorkflowManagementResponse {
    public Boolean success;
	public String error;
    public String secretKey;
    
	public static WorkflowManagementResponse parse(String json) {
		return (WorkflowManagementResponse) System.JSON.deserialize(json, WorkflowManagementResponse.class);
	}    
}