public with sharing class EmptyJobOrderOutController {
   
    public List<Container_Detail__c>   containers         {get; set;}
    public List<Container_Gate_In__c>  conInList          {get; set;}
    public List<Container_Gate_Out__c> conOutList         {get; set;}
    public Container_Gate_Out__c       conOut             {get; set;}
    public Container_Gate_In__c        conIn              {get; set;}
    public Container_Detail__c         con                {get; set;}
    public Job_Order__c                job                {get; set;}
    public List<Job_Order__c>          jobList            {get; set;}
    public Boolean isEditMode                             {get; set;}
    public Boolean DisableSave                            {get; set;}
    public ISO_Code__c                 iso                {get; set;}
    public Vessel_Visit__c             vesselvissit       {get; set;}
    public Container_Gate_In__c contGateInObj             {get; set;}
    public Boolean contGateOut                            {get; set;}

    public EmptyJobOrderOutController () {
        DisableSave = false;
        containers = new List<Container_Detail__c> ();
        containers = fillContainers (50);
        conIn      = new Container_Gate_In__c();
        conOut     = new Container_Gate_Out__c();
        iso        = new ISO_Code__c();
        con        = new Container_Detail__c();
        job        = new Job_Order__c();
        isEditMode = contGateOut = false;
    }

    // A method that identifies the "IN" type
    public PageReference selectInType () {
        contGateOut = false;
        return null;
    }

    // A method that identifies the "OUT" type
    public PageReference selectOutType () {
        contGateOut = true;
        contGateInObj = new Container_Gate_In__c ();
        return null;
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

    // A method that fetches all containers from containerGetIn object
   // public 
   // A method to fetch the single container details from the Containers Details Object
//   public PageReference fetchContDetails(){
  //      String strContDetails = Apexpages.currentPage().getParameters().get('ContDetails');
       //List<String> params = Apexpages.currentPage().getParameters().get('ContDetails').split ('-');
      // String strContDetails = params.get(1);
      // Integer idx = Integer.valueOf(params.get(0));
      //  System.debug('==>' + strContDetails);
      //  containers = [SELECT Id,Name,ISO__c,Container_Size__c,Container_Type__c 
     //                                    FROM Container_Detail__c WHERE Name =: strContDetails
    //                                     limit 1];
    //    System.debug('conList==>'+ containers);
       // Container_Detail__c container = new Container_Detail__c();  
      //   System.debug('container==>'+ container);
       // container.Name=containers.get(0).Name;
     //   container.ISO__c=conList.get(0).ISO__c;
      //  container.Container_Size__c=conList.get(0).Container_Size__c;
      //  container.Container_Type__c=conList.get(0).Container_Type__c;
      //  System.debug('container==>'+ container);
          // Maintaining the original values
    //  container.Name = containers.get (idx).Name;
  //    System.debug ('container ==> '+container);
     //  containers.set (idx, container);
      
       //  containers.add (container);
    //      System.debug ('containers ==> '+containers);
  //      return null;                                
 //  }
   // A Method to pull Vessel Details
    public PageReference fetchVesselDetails () {
        String strVesselDetails = Apexpages.currentPage().getParameters().get('VesselDetails');
        System.debug('strVesselDetails==>' + strVesselDetails);
        vesselvissit = [SELECT Id,Name,Vessel_Name__c,Voy_No__c,VCN_VIA_No__c FROM
                       Vessel_Visit__c WHERE Vessel_Name__c IN (SELECT Id From Vessel__c
                                                                WHERE Name = : strVesselDetails)
                        limit 1];
        System.debug('vesselvissit==>' + vesselvissit);
       return null;
    }

    // A method to find container and it's ISO code
    public PageReference findContainer () {
        List<String> params = Apexpages.currentPage().getParameters().get('contnr').split ('-');
        System.debug ('params ==> '+ params);
        String containerName = params.get (1);
        Integer idx = Integer.valueOf (params.get (0));
        Container_Detail__c container = [SELECT Id, ISO__r.Name
                                        FROM Container_Detail__c
                                        WHERE Name =: containerName
                                        LIMIT 1];
        String iso = idx +'-' + container.ISO__r.Name;
        System.debug ('iso ==> '+ iso);
        Apexpages.currentPage().getParameters().put ('iso', iso);
        Apexpages.currentPage().getParameters().put ('contName', containerName);
        Apexpages.currentPage().getParameters().put ('contId', container.Id);
        fetchISO ();
        return null;
    } // End method

   // A method to pull ISO
    public PageReference fetchISO (){
        List<String> params = Apexpages.currentPage().getParameters().get('iso').split ('-');
        System.debug ('params ==> '+ params);
        String contName = Apexpages.currentPage().getParameters().get ('contName');
        String contId = Apexpages.currentPage().getParameters().get ('contId');
        String strISO = params.get (1);
        Integer idx = Integer.valueOf (params.get (0));
        List<ISO_Code__c> isocodeList = [Select Type__c, Container_Size__c, Id, Name
                                         FROM ISO_Code__c WHERE Name =: strISO 
                                         limit 1];
        System.debug ('contId ==> '+contId);
        System.debug ('isocodeList ==> '+isocodeList);
        Container_Detail__c container = new Container_Detail__c ();
        if (String.isNotBlank (contId)) container.Id = contId;
        container.ISO__c = isocodeList.get(0).Id;
        container.Container_Size__c = isocodeList.get(0).Container_Size__c;
        container.Container_Type__c = isocodeList.get(0).Type__c;

        // Maintaining the original values
        container.Name = contName == null? containers.get (idx).Name : contName;
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
      // A method that turn on edit mode
    public PageReference editFields () {
        isEditMode = true;
        return null;
    }  
     // A method to fetch Empty Container Details record type
    private static String fetchEmptyContainerType () {
        return [SELECT Id FROM RecordType WHERE Name = 'Empty Container Details' LIMIT 1].Id;
    }
    
    // A method that saves data
    public PageReference saveData () {
        List<Container_Detail__c> containerListToInsert = new List<Container_Detail__c> ();
        List<Container_Detail__c> containerListToUpdate = new List<Container_Detail__c> ();
        if (job != null && job.Id == null)
         job.Job_Order_Date__c=System.now();
         insert job;
            System.debug ('containers ==> '+ containers);
        for (Container_Detail__c container : containers) {
            if (container.Name != null) {
              container.RecordTypeId=fetchEmptyContainerType();
                if (container.Id == null) {
                    container.Job_Order_No_Out__c = job.Id;
                    containerListToInsert.add (container);
              //  update containerListToUpdate;
               /* container.Job_Order_NO__c = job.Id;
                containerListToInsert.add (container);
                insert containerListToInsert;*/
                    System.debug ('container ==> '+ container);
                } else {
                    container.Job_Order_NO__c = job.Id;
               // containerListToUpdate
                    containerListToUpdate.add (container);
              //  insert containerListToInsert;
                /*container.Job_Order_No_Out__c = job.Id;
                 containerListToUpdate.add (container);
                update containerListToUpdate;*/
                    System.debug ('container ==> '+ container);
                }
            }
        } // End for
        System.debug ('containerListToInsert ==> '+ containerListToInsert);
        System.debug ('containerListToUpdate ==> '+ containerListToUpdate);
       if (!containerListToInsert.isEmpty ())
            insert containerListToInsert;
        if (!containerListToUpdate.isEmpty ())
            update containerListToUpdate;
        return new pageReference ('/' + job.Id);
    }
}