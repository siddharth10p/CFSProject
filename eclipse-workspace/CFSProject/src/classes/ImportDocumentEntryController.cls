/**
 * Description: This is a controller class used on document entry page
 *
 * Created By: Siddharth Pandit
 * Created Date: 19/09/2017
 **/
public with sharing class ImportDocumentEntryController {
    public List<Container_Detail__c> containers         {get; set;}
    public List<Document_Detail__c> documents           {get; set;}
    public Document_Detail__c doc                       {get; set;}
    public Container_Detail__c con                      {get; set;}
    public Boolean isEditMode                           {get; set;}
   

    public ImportDocumentEntryController () {
        //containers = new List<Container_Detail__c> ();
        containers = fillContainers (4);
        documents = new List<Document_Detail__c> ();
        doc = new Document_Detail__c ();
        Container_Detail__c container = new Container_Detail__c ();
        containers.add (container);
        isEditMode = false;
    }

    // A method that would add 5 containser initially on page load
   public List<Container_Detail__c> fillContainers (Integer pNum) {
        List<Container_Detail__c> listContainersToReturn = new List<Container_Detail__c> ();
        for (Integer i = 0; i < pNum; i++) {
            Container_Detail__c container = new Container_Detail__c ();
            listContainersToReturn.add (container);
        }
        return listContainersToReturn;
    }
 
    // A method that turn on edit mode
    public PageReference editFields () {
        isEditMode = true;
        return null;
    }

    // Add a new row in document entry table
    public PageReference addContainer () {
        Container_Detail__c aContainer = new Container_Detail__c ();
        containers.add (aContainer);
        return null;
    }

    // Remove the last row from document entry table
    public PageReference removeContainer () {
        Integer lastIndex = containers.size() - 1;
        containers.remove (lastIndex);
        return null;
    }

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
                            ' Importer__c, Number_Of_Packages__c, Duty_Value__c, Id,' +
                            ' B_L_Number__c, Line__c, Weigth_In_Kgs__c, IGM_Date__c,' +
                            ' B_L_Date__c, Name, Account_Holder__c, Volume_In_Cu_Mts__c,'+
                            ' Cargo_Discription__c FROM Document_Detail__c' +
                            whereCls (doc.IGM_NO__c, doc.Name) + ' LIMIT 1';
            List<Document_Detail__c> docList =  Database.query (queryStr);
            if (docList.size () > 0) {
                doc = docList.get (0);
                String strQry = ' SELECT Name, ISO__c, Container_Size__c, Container_Type__c,' +
                                ' Categary__c, Tare_Wt__c, No_Of_Packages__c,' +
                                ' Weigth_In_Kgs__c, FCL_LCL_mode__c, Delivery__c, ' +
                                ' Delivery_Mode__c, Seal_No_1__c, Id FROM Container_Detail__c' +
                               ' WHERE Item_No__c = ' + '\'' +  doc.Id + '\'';
                System.debug ('strQry ==> '+ strQry);
                containers = Database.query (strQry);
                System.debug ('containers ==> '+ containers);
            }
            else 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                                    'INFO: No matching data.'));
            if (doc != null) {
                isEditMode = false;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                    'Error: Invalid Input.'));
        }
        return null;
    } // End method
 // A method to validate if the weight is mismatch then throw error message
    public Boolean isWeightSame (Decimal pWeight) {
        System.debug ('doc.Weigth_In_Kgs__c  ==> '+ doc.Weigth_In_Kgs__c);
        doc.Weigth_In_Kgs__c = doc.Weigth_In_Kgs__c == null ? 0 : doc.Weigth_In_Kgs__c;
        if (doc.Weigth_In_Kgs__c != pWeight)
        return false;
        return true;
    }
    // A method to validate if No Of Packages is mismatch then throw error message
     public Boolean isNoOfPackage (Decimal pPackages){
     System.debug ('doc.Number_Of_Packages__c  ==> '+ doc.Number_Of_Packages__c);
     doc.Number_Of_Packages__c = doc.Number_Of_Packages__c == null ? 0 :
                                doc.Number_Of_Packages__c;
     if (doc.Number_Of_Packages__c != pPackages)
        return false;
        return true;
     
     }
    // A method that saves data
    public PageReference saveData () {
        List<Container_Detail__c> containerListToUpdate = new List<Container_Detail__c> ();
        System.debug ('doc ==> '+ doc);
        Decimal weight = 0;
        Decimal Packages = 0;
        if (doc != null && doc.Id == null) insert doc;
        for (Container_Detail__c container : containers) {
            if (container.Name != null) {
                weight += container.Weigth_In_Kgs__c == null ? 0 : container.Weigth_In_Kgs__c;
                packages += container.No_Of_Packages__c == null ? 0 : 
                            container.No_Of_Packages__c;
                container.Item_No__c = doc.Id;
                containerListToUpdate.add (container);
                System.debug ('container ==> '+ container);
            }
        } // End for
        System.debug ('weight ==> '+ weight);
        if((isWeightSame (weight)) && (isNoOfPackage(Packages))) {
            if (!containerListToUpdate.isEmpty ())
                insert containerListToUpdate;
                isEditMode=false;
                System.debug ('containerListToUpdate ==> '+ containerListToUpdate);
                
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'Error: Kindly assure the Weight and Packages of containers isn\'t matching'+
                  ' with document entry detail.'));
            delete doc;
        }
    return NULL;
    }

    // A method to fetch IGM
    public PageReference fetchIGM () {
        String strIGM = Apexpages.currentPage().getParameters().get('igm');
        System.debug ('strIGM ==> '+strIGM);
        List<Vessel_Visit__c> vesselVisitList = [SELECT Line_Id__c, IGM_Date__c, Id,
                                                        Line_Id__r.Name
                                                FROM Vessel_Visit__c
                                                WHERE Name = : strIGM
                                                LIMIT 1];
        System.debug ('vesselVisit ==> '+vesselVisitList);
        doc = new Document_Detail__c ();
        doc.IGM_NO__c = vesselVisitList.get (0).Id;
        doc.IGM_Date__c = vesselVisitList.get (0).IGM_Date__c;
        doc.Line__c = vesselVisitList.get (0).Line_Id__c;
        return null;
    }

    // A method to pull containers
    public PageReference fetchContrainers () {
        return null;
    }

    // A method to pull ISO
    public PageReference fetchISO (){
        List<String> params = Apexpages.currentPage().getParameters().get('iso').split ('-');
        String strISO = params.get (1);
        Integer idx = Integer.valueOf (params.get (0));
        List<ISO_Code__c> isocodeList = [Select Type__c, Container_Size__c, Id, Name
                                         FROM ISO_Code__c WHERE Name =: strISO LIMIT 1];
        System.debug ('params ==> '+params);
        System.debug ('isocodeList ==> '+isocodeList);
        Container_Detail__c container = new Container_Detail__c();
        container.ISO__c = isocodeList.get(0).Id;
        container.Container_Size__c = isocodeList.get(0).Container_Size__c;
        container.Container_Type__c = isocodeList.get(0).Type__c;

        // Maintaining the original values
        container.Name = containers.get (idx).Name;
        container.Categary__c = containers.get (idx).Categary__c;
        container.Tare_Wt__c = containers.get (idx).Tare_Wt__c;
        container.Delivery_Mode__c = containers.get (idx).Delivery_Mode__c;
        container.Seal_No_1__c = containers.get (idx).Seal_No_1__c;
        container.No_Of_Packages__c = containers.get (idx).No_Of_Packages__c;
        container.Weigth_In_Kgs__c = containers.get (idx).Weigth_In_Kgs__c;
        container.FCL_LCL_mode__c = containers.get (idx).FCL_LCL_mode__c;
        container.Delivery__c = containers.get (idx).Delivery__c;
        System.debug ('container ==> '+container);
        containers.set (idx, container);
        System.debug ('containers ==> '+containers);
       return null;
    }
}