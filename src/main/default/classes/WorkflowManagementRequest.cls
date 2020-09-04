public class WorkflowManagementRequest {
    public String id;
    public String agentid;
	
	public static WorkflowManagementRequest parse(String json) {
		return (WorkflowManagementRequest) System.JSON.deserialize(json, WorkflowManagementRequest.class);
	}
}