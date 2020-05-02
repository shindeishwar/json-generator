public with sharing class JSONGeneratorSettingSelector {

    public List<JSON_Generator_Setting__mdt> getSettingByGrpName(String settingGrpName) {

        return [SELECT Id,
                        Add_if_Null__c,
                        Value_Element_Data_Type__c,
                        JSON_Element_Type__c,
                        JSON_Field_Name__c,
                        Key__c,
                        Parent_Key__c,
                        Setting_Group_Name__c,
                        SObject_Field_API_Name__c,
                        Value_Default__c
                FROM JSON_Generator_Setting__mdt
                WHERE  Setting_Group_Name__c =:settingGrpName];

    }
}
