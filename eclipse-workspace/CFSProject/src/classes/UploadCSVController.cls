/**
 * Description: This class provides upload csv feature on VF page.
 **/
public with sharing class UploadCSVController {
    public Blob csvBlobBody                             {get; set;}
    public List<Container_Detail__c> containerList      {get; set;}
    public List<ContainerWrpToDisplay> contWrpList      {get; set;}
    public Boolean showImportBtn                        {get; set;}

    // Private variables
    private String csvAsString;
    private List<String> csvRows;
    private static Boolean showError;
    public static Savepoint sp;
    private Map<String, String> contNumVesselDetailsMap;
    private Map<String, String> vesselNameVCNMap;

    public uploadCSVController () {
        showImportBtn = false;
        // Initializing variables
    } // End constructor

    private static String insertJobOrder (ContainerWrpToDisplay conWrp) {
        sp = Database.setSavepoint ();
        Job_Order__c jobOrder = new Job_Order__c ();
        jobOrder.Line__c = retrieveAccRecord (conWrp.line);
        jobOrder.RecordTypeId = fetchEmptyJobOrderType ();
        System.debug ('showError ==> '+ showError);
        if (showError == null || showError == false) {
            insert jobOrder;
            System.debug ('jobOrder ==> '+ jobOrder);
            return jobOrder.Id;
        }
        return null;
    } // End method

    public PageReference uploadData () {
        List<Container_Detail__c> listContainerToInsert = new List<Container_Detail__c> ();
        String jobOrderId = insertJobOrder (contWrpList.get (0)); //Job order for assignment
        System.debug ('vesselNameVCNMap ==> '+ vesselNameVCNMap);
        Map<String, Vessel_Visit__c> comKeyVesselMap = retrieveVessels (contNumVesselDetailsMap);
        System.debug ('comKeyVesselMap ==> '+ comKeyVesselMap);
        System.debug ('jobOrderId ==> '+ jobOrderId);
        if (!contWrpList.isEmpty () && jobOrderId != null) {
            for (ContainerWrpToDisplay aContainer : contWrpList) {
                String vesselId;
                ISO_Code__c isoCode = retrieveISORecord (aContainer.ISO);
                if (isoCode == null || comKeyVesselMap == null) {
                    Database.rollback (sp); // rolling back everything
                    return null;
                }
                if (contNumVesselDetailsMap.containsKey (aContainer.contNo)) {
                    String combinationKey = contNumVesselDetailsMap.get (aContainer.contNo);
                    System.debug ('combinationKey ==> '+ combinationKey);
                    if (comKeyVesselMap.containsKey (combinationKey))
                        vesselId = comKeyVesselMap.get (combinationKey).Id;
                }
                Container_Detail__c container = new Container_Detail__c ();
                container.Name = aContainer.contNo;
                container.Weigth_In_Kgs__c = Decimal.valueOf (aContainer.weight);
                container.Container_Status__c = aContainer.constatus;
                container.ISO__c = isoCode.Id;
                container.Container_Type__c = isoCode.Type__c;
                container.Container_Size__c  = isoCode.Container_Size__c;
                container.Vessel_Id__c = vesselId; 
                container.Job_Order_NO__c = jobOrderId;
                System.debug ('container ==> '+ container);
                listContainerToInsert.add (container);
            } // End for
            System.debug ('listContainerToInsert ==> '+ listContainerToInsert);
            if (!listContainerToInsert.isEmpty ()) {
                try {
                    insert listContainerToInsert;
                    return new PageReference('/'+ jobOrderId);
                } catch (DmlException e) {
                    Database.rollback (sp); // rolling back everything
                    return null;
                }
            }
        } // End if
        return null;
    } // End method

    // A method that splits the combination key and pring vessel name and vcn num
    private static String extractVesselVCNNo (String pVesselVCN) {
        System.debug ('pVesselVCN ==> '+ pVesselVCN);
        List<String> vessVCN = pVesselVCN.split ('%-%');
        System.debug ('vessVCN ==> '+ vessVCN);
        String vessName;
        if (vessVCN.size () > 1)
        vessName = 'Vessel Name: ' + vessVCN.get (0) +' & VCN No: ' + vessVCN.get (1) + ' | ';
        else {
            vessName = vessVCN.get (0);
        }
        return vessName;
    }

    // A method to fetch Vessel record
    private static Map<String, Vessel_Visit__c> retrieveVessels (Map<String, String> pVessNameVCNMap) {
      System.debug ('pVessNameVCNMap ==> '+ pVessNameVCNMap);
      Set<String> vesselFoundSet = new Set <String> ();
      Map<String, Vessel_Visit__c> vesselKeyIdMap = new Map<String, Vessel_Visit__c> ();
        for (Vessel_Visit__c aVessel : [SELECT Id, Name, Vessel_Name__c, VCN_VIA_No__c,
                                                Vessel_Name__r.Name, Vessel_VCN_Key__c
                                    FROM Vessel_Visit__c
                                    WHERE Vessel_VCN_Key__c =: pVessNameVCNMap.values ()]) {
            vesselKeyIdMap.put (aVessel.Vessel_VCN_Key__c , aVessel);
            System.debug ('aVessel ==> '+ aVessel);
            vesselFoundSet.add (aVessel.Vessel_VCN_Key__c);
        }
        System.debug ('vesselKeyIdMap ==> '+ vesselKeyIdMap);
        String vesselName = '';
        for (String contNo : pVessNameVCNMap.keySet ()) {
            if (!vesselFoundSet.contains (pVessNameVCNMap.get (contNo))) {
                vesselName += extractVesselVCNNo (pVessNameVCNMap.get (contNo));
            }
        }
        if (String.isNotBlank (vesselName)) {
            vesselName.removeEnd (' | ');
            ApexPages.addmessage (new ApexPages.message (ApexPages.severity.Error,
                   vesselName + ' does / do not exist kindly create vessel masters.'));
            showError = true;
        } else {
            return vesselKeyIdMap;
            showError = false;
        }
       return null;
    }

// A method to fetch Account record
    private static String retrieveAccRecord (String pLine) {
        String lineName = pLine.trim();
        System.debug ('lineName ==> '+ lineName);
        List<Account> accList = [SELECT Id, Name
                                    FROM Account
                                    WHERE Name =: lineName];
        System.debug ('accList ==> '+ accList);
        if (accList.size () > 0) {
            return accList.get (0).Id;
            showError = false;
        }
        else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,
                   pLine + ' does not exist kindly create a line master.'));
            showError = true;
        }
           return null;
    }

    // A method to fetch ISO record
    private static ISO_Code__c retrieveISORecord (String pISOCode) {
        String isoCode = pISOCode.trim();
        List<ISO_Code__c> isoList = [SELECT Id, Name, Container_Size__c, Type__c
                                    FROM ISO_Code__c
                                    WHERE Name =: isoCode];
                                  
        if (isoList.size () > 0)
            return isoList.get (0);
        else
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,
                   pISOCode + ' does not exist kindly create an ISO master.'));
            return null;
    }

    // A method to fetch Empty Job Order record type
    private static String fetchEmptyJobOrderType () {
        return [SELECT Id FROM RecordType WHERE Name = 'Empty Job Order' LIMIT 1].Id;
    }

    // A method to fetch Empty Job Order record type
    private static String fetchEmptyContainerType () {
        return [SELECT Id FROM RecordType WHERE Name = 'Empty Container Details' LIMIT 1].Id;
    }

    // A method that creates ISO code if doesn't exist
    private static String createISO (String pISOCode) {
        ISO_Code__c isoCode = new ISO_Code__c (Name = pISOCode);
        insert isoCode;
        return isoCode.Id;
    } // End method

    public void getDisCSVData () {
        showImportBtn = true;
        csvRows = new List<String> ();
        contWrpList = new List<ContainerWrpToDisplay> ();
        vesselNameVCNMap = new Map<String, String> ();
        contNumVesselDetailsMap = new Map<String, String> ();
        try{
            csvAsString = csvBlobBody.toString ();
            csvRows = csvAsString.split ('\n');
            for(Integer i= 1; i < csvRows.size (); i++) {
               ContainerWrpToDisplay contWrp = new ContainerWrpToDisplay ();
               List<String> fieldList = csvRows.get (i).split(',');
               contWrp.contNo = fieldList.get (1);
               contWrp.ISO = fieldList.get (2);
               contWrp.weight = fieldList.get (3);
               contWrp.line = fieldList.get (4);
               contWrp.vessel = fieldList.get (5);
               contWrp.vcn = fieldList.get (6);
               contWrp.constatus = fieldList.get (7);
               contWrpList.add (contWrp);
               contNumVesselDetailsMap.put (contWrp.contNo, contWrp.vessel+'%-%'+contWrp.vcn);
               vesselNameVCNMap.put (contWrp.vessel, contWrp.vcn);
            } // End for
            System.debug ('vesselNameVCNMap ==> '+ vesselNameVCNMap);
            System.debug ('contNumVesselDetailsMap ==> '+ contNumVesselDetailsMap);
        //insert acclist;
         //   return contWrpList;
        }
        catch (Exception e) {
            ApexPages.Message errorMessage = new ApexPages.Message (ApexPages.severity.ERROR,
            'An error has occured while uploading CSV file.');
            ApexPages.addMessage(errorMessage);
        }
      //  return null;
    } // End method

    public class ContainerWrpToDisplay {
        public String contNo        {get; set;}
        public String ISO           {get; set;}
        public String weight        {get; set;}
        public String constatus     {get; set;}
        public String sealNo        {get; set;}
        public String line          {get; set;}
        public string vessel        {get; set;}
        public string vcn           {get; set;}
    }
}