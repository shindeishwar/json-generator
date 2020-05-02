public with sharing class JSONGeneratorService {
    private static JSONGeneratorServiceImpl service(String settingGroupName) 
        { return new JSONGeneratorServiceImpl(settingGroupName); }

    public static String generateJSONString(String settingGrpName, List<Sobject> sObjectList){
        return service(settingGrpName).generateJSONString(sObjectList);
    }

    /**
    * Generate the JSON data from provided SObjects and metadata config
    * @param - List<Sobject> - SObject List from which JSON is generated
    * @param: String settingAPIName (JSON Setting Name)
    * @return: Object - JSON data
    */
    public static Object gatherJSONData(String settingGrpName, List<SObject> sObjectList){
        return service(settingGrpName).gatherJSONData(sObjectList);
    }

    public Set<String> getFields(String settingGroupName){
        return service(settingGrpName).getFields(sObjectList);
    }

}
