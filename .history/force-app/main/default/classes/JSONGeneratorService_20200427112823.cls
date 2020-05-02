public with sharing class JSONGeneratorService {
    private static JSONGeneratorServiceImpl service(String settingGroupName) 
        { return new JSONGeneratorServiceImpl(settingGroupName); }

    /**
    *  Generate the JSON String from JSON_Generator_Setting__mdt metadata
    * @param: String settingAPIName (JSON Setting Name)
    * @param - List<Sobject> - SObject List from which JSON is generated
    * @return: String - generated JSON string.
    */
    public static String generateJSONString(String settingGroupName, List<Sobject> sObjectList){
        return service(settingGroupName).generateJSONString(sObjectList);
    }

    /**
    * Generate the JSON data from provided SObjects and metadata config
    * @param - List<Sobject> - SObject List from which JSON is generated
    * @param: String settingAPIName (JSON Setting Name)
    * @return: Object - JSON data
    */
    public static Object gatherJSONData(String settingGroupName, List<SObject> sObjectList){
        return service(settingGroupName).gatherJSONData(sObjectList);
    }

    /**
    * Get field API Name set from JSON_Generator_Setting__mdt. It will be useful to generate dynamic SOQL
    * @param: String settingAPIName (JSON Setting Name)
    * @return: Set<String> - field api name set. It will be blank if there is no value found for SObject_Field_API_Name__c.
    */
    public static Set<String> getFields(String settingGroupName){
        return service(settingGroupName).getFields();
    }

}
