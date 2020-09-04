/*
*   This is the Base class of the Data Access Layer. Having a Data Access Layer supports the seperation of the Data Model with the rest of the code  
*   Any interaction of with the Data Model should utilize an extension of this class
*   Benefits: 
*   - Code reusability since ceratin SOQL queries tend to be tailored for certain needs. 
*   - Maintainability is supported since adding a new field to a centralized query makes it available every where
*   - If a certain object was to take over the functionality of an existing object, there is a centalized place to replace it and see its impacts.  This is 
*     specially so when replacing a managed package with another manage package or with a internal implementation
*/
public abstract inherited sharing class DALBase {
    List<String> FieldList;
    private List<String> excludeFields ;

    Public DALBase()
    {
        excludeFields = getExcludeFields();
        FieldList = getSObjectFieldList();
    }

    public virtual List<String> getExcludeFields() {
        return new List<String>{'SystemModstamp'};
    }

    public virtual List<String> getSObjectFieldList() {
    	List<String> flds = new List<String>();
    	Schema.SObjectType objType = Schema.getGlobalDescribe().get(getSObjectName());
    	Schema.DescribeSObjectResult objDescribe = objType.getDescribe(); 
    	
    	Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        for(Schema.SObjectField fld : fieldMap.values()) {
            String fldName = fld.getDescribe().getName();
            if(!excludeFields.contains(fldName)) { 
                flds.add(fldName);
            }
        }
                
    	return flds;
    }

    public String getFieldListString()
    {
        String sFieldList = null;
        for(String field : FieldList)
        {
            sFieldList = ( sFieldList==null ? field : sFieldList + ',' + field );            
        }
        return sFieldList;
    }

    public String getSObjectName()
    {
        return getSObjectType().getDescribe().getName();
    }

    abstract Schema.SObjectType getSObjectType();
}