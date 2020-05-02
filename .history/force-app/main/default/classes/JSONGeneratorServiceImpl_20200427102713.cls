public with sharing class JSONGeneratorServiceImpl {
    
    /**
    * Get field API Name set from JSON_Generator_Setting__mdt. It will be useful to generate dynamic SOQL
    * @param: String settingAPIName (JSON Setting Name)
    * @return: Set<String> - field api name set. It will be blank if there is no value found for SObject_Field_API_Name__c.
    */
    public Set<String> getFields(String settingGroupName){

        Set<String> fieldSet = new Set<String>();
        JSONGeneratorSettingSelector jsonSelector = new JSONGeneratorSettingSelector();
        for(JSON_Generator_Setting__mdt settingsRec : jsonSelector.getSObjectFieldsByGrpName(settingGroupName)) {

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
    public String generateJSONString(String settingGrpName, List<Sobject> sObjectList){

        //get JSON Generator Setting records 

        Object jsonData = gatherJSONData(settingGrpName, sObjectList);
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
    public Object gatherJSONData(String settingGrpName, List<SObject> sObjectList){
        //initialze the JSON setting config
        JSONGeneratorUtil jsonConfig =new JSONGeneratorUtil(settingGrpName);
        //check if root is present, else throw an exception
        if( jsonConfig.rootSetting == null ){
            throw new JSONGeneratorUtil.ConfigException('No root record found while generating JSON request for the api - '+ settingGrpName);
        }
        //get root element
        Object root = jsonConfig.getElement(jsonConfig.rootSetting);
        String rootName = jsonConfig.rootSetting.Key__c;

        //for each Sobject generate process JSON request
        for(SObject sObj : sObjectList){
            jsonConfig.getChildren(root, rootName, sObj);
        }

        return root;
    }
    
}
