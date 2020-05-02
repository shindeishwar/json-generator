# OVERVIEW

This utility used to generate the JSON string/data from Sobject records on preconfigured JSON settings in metadata.

# DATA MODEL

This utility uses the metadata - JSON Generator Setting (JSON_Generator_Setting__mdt) to define the JSON configuration. 

![](images/Custom%20Metadata%20Types%20%20%20Salesforce.png)

<table>
  <tr>
    <td>Field Label</td>
    <td>Data Type</td>
    <td>Usage</td>
  </tr>
  <tr>
    <td>Add if Null</td>
    <td>Checkbox</td>
    <td>If true, then include the field in JSON even though field value is null. 
If false, field will be excluded if field value is null.

Default is true.</td>
  </tr>
  <tr>
    <td>JSON Element Type</td>
    <td>Picklist</td>
    <td>Indicate element type in JSON structure. 

Currently supported element type - List, Map, ListValueElement, MapValueElement</td>
  </tr>
  <tr>
    <td>Value Element Data Type</td>
    <td>Picklist</td>
    <td>Expected data type of Value Element in JSON string. Specify for JSON Element Type = MapValueElement or ListValueElement

Supported Data Types - String, Integer, Decimal, Boolean, Date, DateTime.</td>
  </tr>
  <tr>
    <td>JSON Field Name</td>
    <td>Text(255)</td>
    <td>Value key/field name in JSON string</td>
  </tr>
  <tr>
    <td>Key</td>
    <td>Text(255)</td>
    <td>Key (unique with-in JSON group settings records) to identify the specific record and create JSON hierarchy</td>
  </tr>
  <tr>
    <td>Parent Key</td>
    <td>Text(255)</td>
    <td>Parent JSON element record key</td>
  </tr>
  <tr>
    <td>Setting Group Name</td>
    <td>Text(255)</td>
    <td>JSON setting group name. Used to isolate groups of records for specific JSON creation.

You can specify different JSON configurations by grouping related records with unique Setting Group Name</td>
  </tr>
  <tr>
    <td>SObject Field API Name</td>
    <td>Text(255)</td>
    <td>Sobject field from which we need to read data for ValueElement. Specify current sobject or parent sobject fields (with dot notation).

Only supports current SObject and Parent Sobject records.</td>
  </tr>
  <tr>
    <td>Value - Default</td>
    <td>Text(255)</td>
    <td>Specify if you want to include any default value for JSON field. 

Default field will have higher precedence and will ignore the SObject field detail specified in setting. 
Useful when API expects to add standard/dummy values for compatibility purposes.</td>
  </tr>
  <tr>
    <td>Label</td>
    <td>Text(40)</td>
    <td>Standard Metadata Setting label </td>
  </tr>
  <tr>
    <td>JSON Generator Setting Name</td>
    <td>Text(40)</td>
    <td>Standard Metadata Setting Name - unique across metadata records.</td>
  </tr>
</table>


# CONSIDERATIONS

* Supports SObjects and related parent Sobjects fields. Child records are not handled.

* Supported JSON elements - Map, List, MapValueElement, ListValueElement

* Starting element should be specified with the key as root.

* You need to specify the Data Type for value elements (MapValueElement, ListValueElements) which will be used to determine JSON value type

* Supported value element data types - String, Integer, Decimal, Boolean, Date, DateTime.

* You can specify the default field value. If the default value is present, then the system will use this value rather than calculating from the Sobject field.

    * Date and DateTime fields are defaulted with System.now() date and datetime and ignore value specified in value default. You can change this behavior as per your need.

* You can avoid the null fields getting added in JSON using the Add_if_Null attribute.

* Date and DateTime currently using below format. You can change it if you need to by updating the static variable in JSONGeneratorServiceImpl class.

	* public static String DATE_FORMAT_STRING = 'yyyy-MM-dd';

	* public static String DATETIME_FORMAT_STRING =  'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';

* JSONGeneratorService class exposed below 3 static methods

   1. public static String **generateJSONString(String settingGrpName, List\<Sobject> sObjectList)**
    
        * This method will process the record list on the configuration specified for JSOn setting group name.

        * **Params** 

            * settingGrpName - JSON Setting Group Name to identify configuration related to JSON requests.

            * sObjectList - list of records which need to be processed for a JSON request. Ensure you are including all fields used in JSON settings. You can use getFields method get a list of field specified in JSON configuration.
           

        * **Return** : String

            * JSON Data serialized in string format.
  
  
  2. public static Object **gatherJSONData(String settingGrpName, List\<SObject> sObjectList)**

        * generateJSONString method is calling this method internally to obtain JSON data object. You can use this method in case you want to serialize data by your own or process the portion of complex JSON using this utility.

        * **Params** 

            * settingGrpName - JSON Setting Group Name to identify configuration related to JSON requests.

            * sObjectList - list of records which need to be processed for a JSON request. Ensure you are including all fields used in JSON setting. You can use getFields method get a list of field specified in JSON configuration,

        * **Return** : Object

            * JSON Object.


  3. public static Set\<String> **getFields(String settingGrpName)**

        * Provide the Sobject fields used in JSON group setting configuration. You can use this in dynamic query generation. Any addition/removal of fields from JSON setting will not require the code modification.

        * **Params** 

            * settingGrpName - JSON Setting Group Name to identify configuration related to JSON requests.

        * **Return** : Set\<String>

            * Sobject field api name set.

# EXAMPLE

### JSON format :

	[ { 
	    "accountName" : "",  
	    "type" : "",  "noOfEmployees" : ,  
	    "address" : {  
			 "BiLling City" : "",  
			 "Billing Country" : ""  
			 },  
	   "id": "",  
	   "isCustomer" : true 
	  } ]

### JSON Setting Configuration:

![](images/Account%20Sample%20JSON%20records.png)

### Call JSONGeneratorService class

	String jsonGrpName = 'Account Sample JSON'; //JSON Setting Group Name

	List\<String> fieldNameList = new List\<String>();
	fieldNameList.addAll(JSONGeneratorService.getFields(jsonGrpName));//get fields in list of string so that we can use join operator

	List\<Account> accountList = Database.query('Select '+ String.join(fieldNameList,',')+' from Account Where id In (\'0010K00001iwgeQQAQ\', \'0010K00001uU7XLQA0\')'); //form query and fetch accounts

	String jsonString = JSONGeneratorService.generateJSONString(jsonGrpName,accountList);//call JSONGeneratorUtil method to get JSON String

### Output

	[ {  
	  "accountCreatedOn" : "2018-04-22",
	  "accountName" : "ABC Labs",
	  "type" : "Agriculture",
	  "accountAddress" : {
	    "country" : "United States",
	    "city" : "San Jose"
	  },
	  "id" : "0010K00001iwgeQQAQ",
	  "isCustomer" : true,
	  "noOfEmployees" : 123
	}, {  
	  "accountCreatedOn" : "2018-12-19",
	  "accountName" : "accenture",
	  "type" : "Banking",
	  "accountAddress" : {
	    "country" : "US",
	    "city" : "Sunnyvale"
	  },
	  "id" : "0010K00001uU7XLQA0",
	  "isCustomer" : true
	} ]
