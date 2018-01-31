/**
 * Description: This is a controller class used on  Empty Container InsideGate page
 *
 * Created By: Bhushan Pardhi
 * Created Date: 05/11/2017
 **/
public with sharing class EmptyContainerInsideGateController {
    public List<Container_Detail__c>  containers         {get; set;}
    public List<Container_Gate_In__c> conInList          {get; set;}
    public Container_Gate_In__c       conIn              {get; set;}
    public List<Document_Detail__c>   documents          {get; set;}
    public Document_Detail__c         doc                {get; set;}
    public Container_Detail__c        con                {get; set;}
    public Job_Order__c               job                {get; set;}
    public List<Job_Order__c>         jobList            {get; set;}
    public Boolean isEditMode                            {get; set;}
    public Boolean DisableSave                           {get; set;}
    public Boolean readOnly                              {get; set;}
  
    public EmptyContainerInsideGateController () {
        
        DisableSave = false;
        conInList  = new List<Container_Gate_In__c>();
        conInList.add(new Container_Gate_In__c());
        conIn      = new Container_Gate_In__c();
        containers = new List<Container_Detail__c>();
        documents  = new List<Document_Detail__c>();
        doc        = new Document_Detail__c();
       // con        = new Container_Detail__c();
        job        = new Job_Order__c();
        isEditMode = false;
        readOnly   = true;
        retrieveConDe ();
    }
    // A method that turn on edit mode
    public PageReference editFields () {
        isEditMode = true;
        return null;
    }  
    // A method to fetch Container Details before
    public PageReference retrieveConDe () {
    	System.debug('getParameters  ==>' + Apexpages.currentPage().getParameters());
        String strConId = Apexpages.currentPage().getParameters().get ('container');
        System.debug ('strConId ==> '+strConId);
        List<Container_Detail__c> containerdetaillist = [SELECT Container_Size__c,Container_Type__c,
                                                                Tare_Wt__c,Issued_Seal_No__c,
                                                                Port_Out_Date__c,Port_Out_EIR_No__c,
                                                                Container_Tag__c,Gate_In_Date__c,
                                                                Job_Order_NO__c, Id, Name
                                                                FROM Container_Detail__c
                                                                WHERE Id = : strConId 
                                                                limit 1
                                                        ];
        System.debug ('containerdetail ==> '+containerdetaillist);
       if(containerdetaillist.size() > 0){
        con = containerdetaillist.get(0);
       }
       List<Job_Order__c> jobList = [SELECT Line__c,Account_Holder__c,Liner_Agent__c,DO_No__c, Id
                                     FROM Job_Order__c
                                     WHERE  Id IN (SELECT Job_Order_NO__c 
                                                   FROM Container_Detail__c
                                                   WHERE Id = : strConId) 
                                      ];
         System.debug ('jobList ==> '+jobList); 
         if(jobList.size() > 0){
         job                   = jobList.get(0);
         }
      return null;
    }
      // A method to fetch Empty Container Details record type
    private static String fetchEmptyContainerType () {
        return [SELECT Id FROM RecordType WHERE Name = 'Empty Container Inside' LIMIT 1].Id;
    }
    // this method is to serch the existing records 
    public PageReference searchConIn () {
    //	retrieveConDe ();
    System.debug('getParameters  ==>' + Apexpages.currentPage().getParameters());
        String strconD = Apexpages.currentPage().getParameters().get('container');
        System.debug ('strconD ==> '+strconD);
        List<Container_Detail__c> containerdetaillist = [SELECT Container_Size__c,Container_Type__c,
                                                                Tare_Wt__c,Issued_Seal_No__c,
                                                                Port_Out_Date__c,Port_Out_EIR_No__c,
                                                                Container_Tag__c,Gate_In_Date__c,
                                                                Job_Order_NO__c,Id
                                                         FROM Container_Detail__c
                                                         WHERE Name = : strconD 
                                                         limit 1
                                                        ];
        System.debug ('containerdetail ==> '+containerdetaillist);
        con = containerdetaillist.get(0);
        List<Job_Order__c> jobList = [SELECT Line__c,Account_Holder__c,Liner_Agent__c,DO_No__c, Id
                                      FROM Job_Order__c
                                      WHERE  Id IN (SELECT Job_Order_NO__c FROM Container_Detail__c
                                                   WHERE Name = : strconD) 
                                      ];
         System.debug ('jobList ==> '+jobList); 
         job                   = jobList.get(0);
         List<Container_Gate_In__c> inList = [SELECT Transporter__c,Surveyor__c,Transport__c,
                                                 Truck_Tag__c,Truck_No__c ,Vehicle_Type__c,
                                                 Cargo_Type__c,Yard_Id__c,Driver_Name__c,
                                                 Gate_Pass_No__c,Gate_In_Date__c, Container_No__c,
                                                 Mode_Of_Arrival__c,Status_Type__c,
                                                 Surveyer_EIR_No__c,Damage_Remarks__c,
                                                 Port_Of_Arrival__c,Remarks__c, Id
                                             FROM Container_Gate_In__c
                                             WHERE  Container_No__c IN (SELECT Id 
                                                                        FROM Container_Detail__c
                                                                        WHERE Name = : strconD) 
                                      ];
          conIn=inList.get(0);
          return null;
    } // End method.

   // A Method to Save Data
    public PageReference saveData () {
        try{
             conIn.Gate_In_Date__c = System.now ();
             conIn.RecordTypeId =fetchEmptyContainerType();	
             insert  conIn;
             update job;
         if(conIn.Gate_In_Date__c != null) {
             con.Gate_In_Date__c =conIn.Gate_In_Date__c;//To Fill the date(gate in date) for 
                                                     //container details object
            update con;
         }  
            isEditMode=true;
            return new pagereference ('/' + conIn.Id);
         }
        catch (DmlException ex) {
                  ApexPages.addmessages (ex);
                   return null;
        }  
       return NULL;
    }
    public void Cancel(){
        DisableSave = true;
    }
}