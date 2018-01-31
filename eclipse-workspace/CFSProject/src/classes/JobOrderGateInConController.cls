/**
 * Description: This class provides Gate Out for conatiners via job order on VF page.
 **/
public with sharing class JobOrderGateInConController {
    public Job_Order__c                 job         {get;set;}
    public List<Job_Order__c>           jobList     {get;set;}
    public Container_Detail__c          con         {get;set;}
    public List<Container_Detail__c>    conList     {get;set;}
    public Container_Gate_In__c         conIn       {get;set;}
    public List<Container_Gate_In__c>   conInList   {get;set;}
    
    public  JobOrderGateInConController(){
    job         = new Job_Order__c();
    conIn       = new Container_Gate_In__c();
    jobList     = new List<Job_Order__c>();   
    conList     = new List<Container_Detail__c>();
    conInList   = new List<Container_Gate_In__c>();
    }
    //A Method is for getting container list and job order details. 
    public PageReference fetchContainers() {
        String strjobOd = Apexpages.currentPage().getParameters().get('jobOrd');
        System.debug('==>' + strjobOd);
        conList = [SELECT Name,Id,Job_Order_NO__c,Gate_In_Date__c,Gate_Out_Date__c,
                          Job_Order_NO__r.Job_Order_Date__c,Job_Order_NO__r.DO_No__c,
                          Job_Order_NO__r.Job_Order_For__c
                   FROM Container_Detail__c
                   WHERE  Job_Order_NO__c  IN (SELECT Id 
                                               FROM Job_Order__c  
                                               WHERE Name =: strjobOd)
                                               AND Job_Order_NO__r.Job_Order_For__c = 'IN'
                  ];
        if(conList.size() > 0){
            con=conList.get(0);
         }    
     return null;
    }
    //A Method is for goto page- Container gate In.
    public PageReference redirectToGetInPage () {
        String contId = Apexpages.currentPage ().getParameters ().get ('containerId');
        PageReference pageRef = Page.EmptyContainerInsideGate;
        pageRef.getParameters ().put ('container', contId);
        pageRef.setredirect(true);
        return pageRef;
    }
}