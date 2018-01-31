/**
 * Description: This is a controller class fetches containers to create an invoice for them.
 * The page should only display those containers which invoice is not created yet, this can
 * be found based on Invoice_No__c field.
 *
 *    Author           Date (mm-dd-yyyy)  Version    Changelog
 * Siddharth Pandit    12/12/2017           1.0      Inital draft
 **/
public with sharing class CreateInvoiceController {
    public List<CreateInvoiceWrapper> createInvWrpList {get; set;}
    public String jobOrd                               {get; set;}
    // private variables
    private String jobOrderId;
    private Sobject sobj;

    // Constructor
    public createInvoiceController () {
        jobOrderId = apexpages.currentpage().getparameters().get('jobOrdId');
        System.debug ('jobOrderId ==> '+ jobOrderId);
        createInvWrpList = fetchContainers (jobOrderId);
        System.debug ('createInvWrpList ==> '+ createInvWrpList);
        Id recordId = apexpages.currentpage().getparameters().get('jobOrdId');
        if (recordId.getSObjectType().getDescribe().getName() == 'Job_Order__c')
            sobj = [SELECT Id, Combination_Key__c FROM Job_Order__c 
                    WHERE Id =:recordId LIMIT 1];
        else
            sobj = [SELECT Id, Combination_Key__c, IGM_NO__c FROM Document_Detail__c 
                    WHERE Id =:recordId LIMIT 1];
    }

    // A method to fill wrapper list
    private List<CreateInvoiceWrapper> fetchContainers (String joId) {
        List<CreateInvoiceWrapper> wrpListToReturn = new List<CreateInvoiceWrapper> ();
        for (Container_Detail__c aCont : [SELECT Id, Name, Job_Order_NO__r.Name,
                                                Gate_In_Date__c, Gate_Out_Date__c,
                                                Invoice_No__c, Container_Size__c,
                                                Container_Type__c
                                            FROM Container_Detail__c
                                            WHERE Invoice_No__c = null
                                            AND Gate_Out_Date__c <> null
                                            AND Gate_In_Date__c <> null
                                            AND Job_Order_NO__c = : joId
                                            AND Id NOT IN (SELECT Container_No__c
                                                            FROM Invoice_Item__c)]) {
            wrpListToReturn.add (new CreateInvoiceWrapper (aCont, false));
            jobOrd = aCont.Job_Order_NO__r.Name;
        }
        return wrpListToReturn;
    } // End method

    // A method that returns only selected containers
    public String getSelectedContainerIds () {
        String selectContIds = '';
        for (CreateInvoiceWrapper wrpInstance : createInvWrpList) {
            if (wrpInstance.isSelected) {
                selectContIds += ('\'' + wrpInstance.cont.Id + '\',');
            }
        }
        selectContIds = selectContIds.lastIndexOf(',') > 0 ? 
                '(' + selectContIds.substring(0, selectContIds.lastIndexOf(',')) + ')' :
                selectContIds ;
        System.debug ('selectContIds ==> '+ selectContIds);
        return selectContIds;
    }

    // A method to create invoice for empty cycle
    public PageReference createInvoiceAndItems () {
        Invoice__c invoice = CreateInvoiceUtil.insertInvoice (sobj);
        System.debug ('invoice ==> '+ invoice);
        CreateInvoiceUtil.createInvoiceItems (invoice, getSelectedContainerIds ()); // Creating invoice items
        return new PageReference('/apex/ViewInvoice?invId=' + invoice.Id);
    }

    // Wrapper class
    public class CreateInvoiceWrapper {
        public Container_Detail__c cont {get; set;}
        public Boolean isSelected       {get; set;}

        // Constructor
        public createInvoiceWrapper (Container_Detail__c pCont, Boolean pIsSelected) {
            this.cont = pCont;
            this.isSelected = pIsSelected;
        } // End constructor
    } // End wrapper class
}