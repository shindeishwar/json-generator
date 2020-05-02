public with sharing class JSONGeneratorServiceImpl {
    private String settingGroupName;

    /**
    *  ConfigException class to handle config issues. 
    * */
    public class ConfigException extends Exception{

    }

    public JSONGeneratorServiceImpl(String settingGroupName){
        this.settingGroupName = settingGroupName;
    }
    /**
    * Get field API Name set from JSON_Generator_Setting__mdt. It will be useful to generate dynamic SOQL
    * @param: String settingAPIName (JSON Setting Name)
    * @return: Set<String> - field api name set. It will be blank if there is no value found for SObject_Field_API_Name__c.
    */
    public Set<String> getFields(){

        Set<String> fieldSet = new Set<String>();
        JSONGeneratorSettingSelector jsonSelector = new JSONGeneratorSettingSelector();
        for(JSON_Generator_Setting__mdt settingsRec : jsonSelector.getSObjectFieldsByGrpName(this.settingGroupName)) {

            if(String.isNotBlank(settingsRec.SObject_Field_API_Name__c)){
                fieldSet.add(settingsRec.SObject_Field_API_Name__c);
            }
                
        }

        return fieldSet;
    }

    /**
    *  Generate the JSON String from JSON_Generator_Setting__mdt metadata
    * @param: String settingAPIName (JSON Setting Name)
    * @param - List<Sobject> - SObject List from which JSON is generated
    * @return: String - generated JSON string.
    */
    public String generateJSONString(List<Sobject> sObjectList){

        //get JSON Generator Setting records 

        Object jsonData = gatherJSONData(sObjectList);
        String reqBodyString = JSON.serializePretty(jsonData);
        //System.debug( '-- JSON --- '+ reqBodyString);
        return reqBodyString;

    }

    /**
    * Generate the JSON data from provided SObjects and metadata config
    * @param - List<Sobject> - SObject List from which JSON is generated
    * @param: String settingAPIName (JSON Setting Name)
    * @return: Object - JSON data
    */
    public Object gatherJSONData(List<SObject> sObjectList){
        //initialze the JSON setting config
        JSONSettingConfigUtil jsonConfig =new JSONSettingConfigUtil(this.settingGroupName);
        
        //get root element
       /* Object root = jsonConfig.getElement(jsonConfig.rootSetting);
        String rootName = jsonConfig.rootSetting.Key__c;

        //for each Sobject generate process JSON request
        for(SObject sObj : sObjectList){
            jsonConfig.getChildren(root, rootName, sObj);
        }

        return root;*/
        return null;
    }
    

    private class JSONSettingConfigUtil {

        /**
        * Initilase the rootsetting and jsonSettingsByParentKeyMap by quering 
        * @param: String someId
        * @return: boolean true if success, false if failure
        */
        public JSONSettingConfigUtil(String settingGroupName) {
            JSONGeneratorSettingSelector jsonSelector = new JSONGeneratorSettingSelector();
            for(JSON_Generator_Setting__mdt settingsRec : jsonSelector.getSettingByGrpName(settingGroupName)) {

                if(!jsonSettingsByParentKeyMap.containsKey(settingsRec.Parent_Key__c)){
                    jsonSettingsByParentKeyMap.put(settingsRec.Parent_Key__c, new List<JSON_Generator_Setting__mdt>());
                }
                jsonSettingsByParentKeyMap.get(settingsRec.Parent_Key__c).add(settingsRec);

                if(settingsRec.Key__c == 'root')
                    this.rootSetting = settingsRec;
            }

            //check if root is present, else throw an exception
            if( rootSetting == null ){
                throw new JSONGeneratorServiceImpl.ConfigException('No root record found while generating JSON request for the api - '+ settingGroupName);
            }
        }

        private String DATE_FORMAT_STRING = 'yyyy-MM-dd';
        private String DATETIME_FORMAT_STRING = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
       
        
        //static map tp store json field settng metadata
        private Map<String,List<JSON_Generator_Setting__mdt>> jsonSettingsByParentKeyMap
                = new Map<String,List<JSON_Generator_Setting__mdt>>(); 
        
        //root setting 
        public JSON_Generator_Setting__mdt rootSetting;


        /**
        *  Use JSON_Element_Type__c field of JSON_Generator_Setting__mdt metadata and generate JSON element 
        *       Currently supported Type - List, Map
        * @param: JSON_Generator_Setting__mdt  JSON Setting instance
        * @return: Object - JSON Element
        */
        private Object getElement(JSON_Generator_Setting__mdt setting){
            Object element;

            if(setting.JSON_Element_Type__c == 'List'){
                element = new List<Object>();
            }else{
                element= new Map<String, Object>();
            }
            return element;
        }

        /**
        *  Generic internal method to process the JSON childs elements
        *       
        * @param: Object - Parent JSON Element instance 
        * @param: String - parentName - parentKey  to identify the child setting list
        * @param - Sobject - record : SObject instane which will be used to gather the data
        * @return: none
        */
        private void getChildren(Object parent, String parentName, Sobject record){
            //System.debug(LoggingLevel.INFO,'---- parentName : '+ parentName);
            List<JSON_Generator_Setting__mdt> childRecs= getAllChildrenBasedOnParent(parentName);
            for(JSON_Generator_Setting__mdt cRec :childRecs){
                createChild(parent, cRec, record);
            }
        }

        /**
        *  Generic internal method to get child JSON_Generator_Setting__mdt list from parentKey
        *        
        * @param: String - parentName - parentKey  to identify the child setting list
        * @return: List<JSON_Generator_Setting__mdt>  - child JSON_Generator_Setting__mdt list
        */
        private List<JSON_Generator_Setting__mdt> getAllChildrenBasedOnParent(String parentName){
            List<JSON_Generator_Setting__mdt> childs = new List<JSON_Generator_Setting__mdt>();
            if(jsonSettingsByParentKeyMap.containsKey(parentName)){
                childs = jsonSettingsByParentKeyMap.get(parentName);
            }
        return childs;
        }
        
        /**
        *  Create Child element and append it to parent JSON Element
        *       Supported Element Type - MapValueElement and ListValueElement
        *       
        * @param: Object - parent : Parent JSON Element instance 
        * @param: JSON_Generator_Setting__mdt - childSettingRec : current child setting record
        * @param - Sobject - record : SObject instane which will be used to gather the data
        * @return: none
        */
        private void createChild(Object parent, JSON_Generator_Setting__mdt childSettingRec, Sobject record){

            //#1. Process ValueElement - MapValueElement & ListValueElement by generating the value and then
            // add them to parent JSON Element
            //MapValueElement - key will be a string provided in JSON_Generator_Setting__mdt.JSON_Field_Name__c

            if(childSettingRec.JSON_Element_Type__c == 'MapValueElement'){

                Object value = getJSONFieldValue(childSettingRec, record);
                
                if( value != null || childSettingRec.Add_If_Null__c ){
                    Map<String,Object> parentMap = (Map<String,Object>) parent;
                    parentMap.put(childSettingRec.JSON_Field_Name__c, value);
                }


            } else if(childSettingRec.JSON_Element_Type__c == 'ListValueElement'){

                Object value = getJSONFieldValue(childSettingRec, record);
                //System.debug('--- value :'+value + ' --- Parent '+ parent + ' --childSettingRec '+ childSettingRec);
                if( value != null || childSettingRec.Add_If_Null__c ){
                    List<Object> parentList = (List<Object>) parent;
                    parentList.add(value);
                }
            
        //#2. If not a ValueElement, then create the JSON Element and append it to parent to maintain JSON hierarchy
        } else { 

                Object childObj = getElement(childSettingRec);
                
                if( parent instanceof List<Object>){
                    List<Object> parentList = (List<Object>) parent;
                    parentList.add(childObj);

                }else{
                    Map<String,Object> parentMap = (Map<String,Object>) parent;
                    //can't serailize map with null key value
                    String key = String.isNotBlank(childSettingRec.JSON_Field_Name__c) ? childSettingRec.JSON_Field_Name__c : '';
                    parentMap.put(key, childObj);
                }
                //System.debug(LoggingLevel.INFO,'---- parent : '+ parent);

                //process the child by recursively calling the getChildrent function
                getChildren(childObj, childSettingRec.Key__c ,  record );

            }
        }

        /**
        *  Generate the value from SObject record / JSON_Generator_Setting__mdt.Value_Default__c
        *       Supported data types - Boolean, Decimal. Integer, Date. DateTime
        *        
        * @param: String - parentName - parentKey  to identify the child setting list
        * @return: List<JSON_Generator_Setting__mdt>  - child JSON_Generator_Setting__mdt list
        */
        private Object getJSONFieldValue(JSON_Generator_Setting__mdt otRec, Sobject obj) {
            Object retVal;
            if(String.isNotBlank(otRec.Value_Default__c)){
                retVal = getDefaultValue(otRec.Value_Default__c, otRec.Value_Element_Data_Type__c );
            }
            else {
                retVal = getFieldVal(obj, otRec.SObject_Field_API_Name__c);
                if( otRec.Value_Element_Data_Type__c == 'DateTime'){
                    //system.debug(otRec.SObject_Field_API_Name__c + '---Inside- return val '+ JSON.serializePretty(retVal));
                    retVal = convertDateTime((DateTime)retVal);

                }else if (otRec.Value_Element_Data_Type__c == 'Date'){
                    retVal = (Object)convertDate((DateTime)retVal);

                }else if (otRec.Value_Element_Data_Type__c == 'Integer'){
                    retVal = Integer.valueOf(retVal);

                }else if (otRec.Value_Element_Data_Type__c == 'Decimal'){
                    retVal = Double.valueOf(retVal);
                    retVal = Decimal.valueOf((Double)retVal);

                }else if (otRec.Value_Element_Data_Type__c == 'Boolean'){
                    retVal = Boolean.valueOf(retVal);
                }    
            }
            //system.debug(otRec.SObject_Field_API_Name__c + '--' + otRec.Value_Element_Data_Type__c +'-- return val '+ JSON.serializePretty(retVal));
            return retVal;
        }

        /**
        *  Generate the default value from JSON_Generator_Setting__mdt.Value_Default__c
        *       Supported data types - Boolean, Decimal. Integer, Date. DateTime
        *        
        * @param: String - valueDefault : default value stored in JSON_Generator_Setting__mdt.Value_Default__c
        * @param: String - dataType : expected output data type
        * @return: Object - JSON data element value
        */
        private Object getDefaultValue(String valueDefault, String dataType){
            Object retVal;
                if(dataType	 == 'Boolean')
                    retVal = Boolean.valueOf(valueDefault);
                else if (dataType	 == 'Decimal')
                    retVal = Decimal.valueOf(valueDefault);
                else  if (dataType	 == 'Integer')
                    retVal = Integer.valueOf(valueDefault);
                else if (dataType	 == 'Date')
                    retVal = convertDate(System.now());
                else if (dataType	 == 'DateTime')
                    retVal = convertDateTime(System.now());
                else
                    retval =  valueDefault;
                
            return retVal;
        }

        /**
        *  Convert the datetime value in string format defined at DATETIME_FORMAT_STRING var
        *      
        * @param: DateTime - val : DateTime value
        * @return: String - DateTime in string format
        */
        private String convertDateTime(DateTime val) {
            return (val == null ? null : val.formatGMT(DATETIME_FORMAT_STRING));
        }

        /**
        *  Convert the date value in string format defined at DATE_FORMAT_STRING var
        *      
        * @param: DateTime - val : Date value in datetime format
        * @return: String - Date in string format
        */
        private String convertDate(DateTime val) {
            return (val == null ? null : val.formatGMT(DATE_FORMAT_STRING));
        }

        /**
        *  Access field value from SObject record
        *        
        * @param: Sobject - record : instance which will be used to collect the data 
        * @param: String - fieldName : Sobject field Name
        * @return: Object - JSON data element value
        */
        private Object getFieldVal(Sobject record, String fieldName) {
            Object fieldVal = null;

            if (fieldName.contains('.')) {
                List<String> fieldPath = fieldName.split('\\.');
                for (Integer i = 0; i < fieldPath.size(); i++) {
                    if (i < (fieldPath.size() - 1))
                        record = record.getSobject(fieldPath[i]);
                    else
                            fieldVal = record.get(fieldPath[i]);
                }
            }
            else{
                fieldVal = record.get(fieldName);
            }
        
            return fieldVal;
        }

    }
}
