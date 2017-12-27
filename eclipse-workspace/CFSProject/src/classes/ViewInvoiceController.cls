public with sharing class ViewInvoiceController {
    public InvoiceAndItemWrp invMainWrap {get; set;}

    // Variables
    private static Id recordId;
    private static final String INVOICEOBJ          = 'Invoice__c';
    private static final String INVOICEITMOBJ       = 'Invoice_Item__c';
    private static final String INVOICEITMTAXOBJ    = 'Invoice_Tax_Items__r';

    // Constructor
    public viewInvoiceController () {
        
    }

    public InvoiceAndItemWrp getInvoiceData () {
        recordId = apexpages.currentpage().getparameters().get('invId');
        InvoiceAndItemWrp invWrp = new InvoiceAndItemWrp ();
        invWrp.invoice = fetchInvoice (recordId);
        invWrp.invItemTaxMap = fetchInvoiceItemAndTaxItm (recordId);
        System.debug ('invWrp ==> '+ invWrp);
        invMainWrap = invWrp; // assigning for other variables
        return invWrp;
    }
    // A method to fetch invoice details
    private static Invoice__c fetchInvoice (String invId) {
        List<Schema.FieldSetMember> fieldSet = 
                    SObjectType.Invoice__c.FieldSets.ViewInvoice.getFields();
        String queryStr = UtilityGeneral.buildQuery (fieldSet, INVOICEOBJ);
        queryStr += ' WHERE Id = ' + UtilityGeneral.wrapInSingleQuotes (invId);
        queryStr += ' LIMIT 1';
        System.debug ('queryStr ==> '+ queryStr);
        return Database.query (queryStr);
    } // End method

    // A method to fetch invoice details
    private static Map<Invoice_Item__c, List<Invoice_Tax_Item__c>> 
                                                fetchInvoiceItemAndTaxItm (String invId) {
        Map<Invoice_Item__c, List<Invoice_Tax_Item__c>> mapToReturn = 
            new Map<Invoice_Item__c, List<Invoice_Tax_Item__c>> ();
        List<Schema.FieldSetMember> invTaxItmFields = 
                    SObjectType.Invoice_Tax_Item__c.FieldSets.ViewInvoiceTaxItems.getFields();
        String subQuery = UtilityGeneral.buildQuery (invTaxItmFields, INVOICEITMTAXOBJ);
        String queryStr = ' SELECT Id, Amount__c, Container_No__c, Invoice_No__c,' +
                        'Container_No__r.Name, Tax_Amount__c, Tax_Group__c,' +
                        'Quantity__c, (' + subQuery + ' ) FROM ' + INVOICEITMOBJ;
                queryStr += ' WHERE Invoice_No__c ='+UtilityGeneral.wrapInSingleQuotes (invId);
            System.debug ('queryStr ==> '+ queryStr);
            System.debug ('result ==> '+ Database.query (queryStr));
        for (Invoice_Item__c invItm : Database.query (queryStr)) {
            mapToReturn.put (invItm, invItm.Invoice_Tax_Items__r);
        }
        return mapToReturn;
    } // End method

    public with sharing class InvoiceAndItemWrp {
        public Invoice__c invoice                                               {get; set;}
        public Map<Invoice_Item__c, List<Invoice_Tax_Item__c>> invItemTaxMap    {get; set;}
    }
}