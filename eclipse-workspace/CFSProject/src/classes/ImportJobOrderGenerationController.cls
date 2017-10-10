public with sharing class ImportJobOrderGenerationController {
    public List<Container_Detail__c> containers         {get; set;}
    public Import_Document_Entry__c doc                 {get; set;}

    // A method that appends WHERE clause based off the user's input
    private static String whereCls (String pIGM, String pItem) {
        String whr = ' WHERE '; Boolean firstConditionMet = false;
        if (String.isNotBlank (pIGM)) {
            whr += 'IGM_NO__c = ' + '\''+ pIGM +'\'';
            firstConditionMet = true;
        }
        if (String.isNotBlank (pItem)) {
            if (firstConditionMet) {
                whr += ' AND Name = ' + '\'' + pItem + '\'';
            } else {
                whr += ' Name = ' + '\'' + pItem + '\'';
            }
        }
        return whr;
    }

   // A method to find document and container details based on AGM number or Item number
    public PageReference findDocumentEntry () {
        if (doc != null && (String.isNotBlank (doc.IGM_NO__c) ||
                            String.isNotBlank (doc.Name))) {
            String queryStr = ' SELECT B_O_E_Number__c, Port_of_D__c, CHA__c, Commodity__c,'+
                            ' IGM_NO__c, Assesable_Value__c, B_O_E_Date__c, Port_of_L__c,'+
                            ' Importer__c, Number_Of_Packages__c, Duty_Value__c,' +
                            ' B_L_Number__c, Line__c, Weigth_In_Kgs__c,' +
                            ' B_L_Date__c, Name, Account_Holder__c, Volume_In_Cu_Mts__c,'+
                            ' Cargo_Discription__c FROM Import_Document_Entry__c' +
                            whereCls (doc.IGM_NO__c, doc.Name) + ' LIMIT 1';
            System.debug ('IGM ==> '+ doc.IGM_NO__c);
            System.debug ('Name ==> '+ doc.Name);
            System.debug ('queryStr ==> '+ queryStr);
            List<Import_Document_Entry__c> docList =  Database.query (queryStr);
            if (docList.size () > 0)
                doc = docList.get (0);
            else 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                                    'INFO: No matching data.'));
            if (doc != null) {
               // isEditMode = false;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                    'Error: Invalid Input.'));
        }
        return null;
    } // End method
}