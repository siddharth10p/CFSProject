public with sharing class ViewInvoiceController {
    public InvoiceAndItemWrp invMainWrap            {get; set;}
    public String selectedTaxGroup                  {get; set;}
    public Additional_Tariff__c addTariff           {get; set;}
    public Boolean showPopup                        {get; set;}
    public Boolean showAddTaxBtn                    {get; set;}

    // Variables
    private static Id recordId;
    private static final String INVOICEOBJ          = 'Invoice__c';
    private static final String INVOICEITMOBJ       = 'Invoice_Item__c';
    private static final String INVOICEITMTAXOBJ    = 'Invoice_Tax_Items__r';
    private static Map<String, List<Invoice_Tax_Item__c>> contNameTaxItmListMap;

    // Constructor
    public viewInvoiceController () {
        showAddTaxBtn = false;
    }

    public InvoiceAndItemWrp getInvoiceData () {
        recordId = apexpages.currentpage().getparameters().get ('invId');
        invMainWrap = new InvoiceAndItemWrp ();
        invMainWrap.invoice = fetchInvoice (recordId);
        invMainWrap.invItmTaxWprList = fetchInvoiceItemAndTaxItm (recordId);
        System.debug ('invMainWrap ==> '+ invMainWrap);
        //System.debug ('invWrp ==> '+ invWrp);
       // invMainWrap = invWrp; // assigning for other variables
        return invMainWrap;
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

    // A method to add a subquery
    private static String buildFinalQuery (String pSubQry, String pInvId) {
        return ' SELECT Id, Amount__c, Container_No__c, Invoice_No__c,' +
                        'Container_No__r.Name, Tax_Amount__c, Tax_Group__c,' +
                        'Quantity__c, Total_Amount__c,' +
                        '(' + pSubQry + ' ) FROM ' + INVOICEITMOBJ +
                ' WHERE Invoice_No__c ='+ UtilityGeneral.wrapInSingleQuotes (pInvId) +
                ' ORDER BY Container_No__c';
    }// End method

    // A method to fetch invoice details
    private static List<InvItmWithTaxWrp> fetchInvoiceItemAndTaxItm (String invId) {
        List<InvItmWithTaxWrp> lstInvItmWithTax = new List<InvItmWithTaxWrp> ();
        Map<String, Decimal> contNameAmtMap = new Map<String, Decimal> ();
        contNameTaxItmListMap = new Map<String, List<Invoice_Tax_Item__c>> ();
        List<InvItmWithTaxWrp> listWprToReturn = new List<InvItmWithTaxWrp> ();
        List<Schema.FieldSetMember> invTaxItmFields = 
                    SObjectType.Invoice_Tax_Item__c.FieldSets.ViewInvoiceTaxItems.getFields();
        String subQuery = UtilityGeneral.buildQuery (invTaxItmFields, INVOICEITMTAXOBJ);
        subQuery += ' ORDER BY Name';
        String queryStr = buildFinalQuery (subQuery, invId);
        System.debug ('queryStr ==> '+ queryStr);
        String prevContainer, prevContainerName;
        for (Invoice_Item__c invItm : Database.query (queryStr)) {
            if (!contNameAmtMap.containsKey (invItm.Container_No__c))
                contNameAmtMap.put (invItm.Container_No__c, 0);
                Decimal amt = contNameAmtMap.get (invItm.Container_No__c);
                amt += invItm.Amount__c;
                contNameAmtMap.put (invItm.Container_No__c, amt);
            if (!contNameTaxItmListMap.containsKey (invItm.Container_No__c))
                contNameTaxItmListMap.put (invItm.Container_No__c,
                                            new List<Invoice_Tax_Item__c> ());
                contNameTaxItmListMap.get (invItm.Container_No__c)
                                .addAll (invItm.Invoice_Tax_Items__r);
                if (String.isNotBlank (prevContainer) &&
                    prevContainer != invItm.Container_No__c) {
                    Tax taxInfo = retrieveTaxInfo (contNameTaxItmListMap.get (prevContainer));
                    lstInvItmWithTax.add (new InvItmWithTaxWrp (false, prevContainerName,
                                        contNameAmtMap.get (prevContainer), taxInfo.taxAmt,
                                        contNameAmtMap.get (prevContainer) + taxInfo.taxAmt,
                                        taxInfo.taxDetailList, invItm.Container_No__c));
                }
                prevContainer = invItm.Container_No__c;
                prevContainerName = invItm.Container_No__r.Name;
        } // End for
        Tax taxInfo = retrieveTaxInfo (contNameTaxItmListMap.get (prevContainer));
        lstInvItmWithTax.add (new InvItmWithTaxWrp (false, prevContainerName,
                            contNameAmtMap.get (prevContainer), taxInfo.taxAmt,
                            contNameAmtMap.get (prevContainer) + taxInfo.taxAmt,
                            taxInfo.taxDetailList, prevContainer));
         return lstInvItmWithTax;
    } // End method

    // A method to calculate total tax for invoice items
    private static Tax retrieveTaxInfo (List<Invoice_Tax_Item__c> pTaxItmList) {
        System.debug ('pTaxItmList ==> '+ pTaxItmList);
        Tax tax= new Tax ();
        tax.taxAmt = 0;
        tax.taxDetailList = new List<TaxDetails> ();
        Map<String, Decimal> taxNamePercentMap = new Map<String, Decimal> ();
        Map<String, Decimal> taxNameAmtMap = new Map<String, Decimal> ();
        for (Invoice_Tax_Item__c aTaxItm : pTaxItmList) {
            if (!taxNameAmtMap.containsKey (aTaxItm.Tax_Name__c))
                taxNameAmtMap.put (aTaxItm.Tax_Name__c, 0);
                Decimal amt = taxNameAmtMap.get (aTaxItm.Tax_Name__c) + aTaxItm.Tax_Amount__c;
                taxNameAmtMap.put (aTaxItm.Tax_Name__c, amt);
            tax.taxAmt += aTaxItm.Tax_Amount__c;
            taxNamePercentMap.put (aTaxItm.Tax_Name__c, aTaxItm.Tax_Rate__c);
            
        } // End for
        for (String taxName : taxNamePercentMap.keySet ()) {
            TaxDetails taxDet = new TaxDetails ();
            taxDet.taxName = taxName;
            taxDet.percent = taxNamePercentMap.get (taxName);
            taxDet.taxAmt = taxNameAmtMap.get (taxName);
            tax.taxDetailList.add (taxDet);
        }
        return tax;
    } // End method

    // A method that pulls all tax group to add additional tax
    public List<SelectOption> getTaxGroup () {
        List<SelectOption> options = new List<SelectOption>();
        options.add (new SelectOption ('--None--', '--None--'));
        for (Tax_Group__c txGrp : [SELECT Id, Name FROM Tax_Group__c]) {
            options.add (new SelectOption (txGrp.Id, txGrp.Name));
        }
        return options;
    } // End method

    // A method to enable add additional tax button
    public PageReference enableAdditionalTaxBtn () {
        showAddTaxBtn = true;
        return null;
    }// End method

    // A method to enable add additional tax button
    public PageReference diableAdditionalTaxBtn () {
        showAddTaxBtn = false;
        return null;
    }// End method

    // A method that add additional tax
    public PageReference addAdditionalTariff () {
        insert addTariff;
        showPopup = false;
        return null;
    } // End method

    // A method to initialize additional tax item
    public PageReference addAdditionalTaxItem () {
        showPopup = true;
        addTariff = new Additional_Tariff__c ();
        Boolean flag = false; Id tempContId;
        for (InvItmWithTaxWrp invTax : invMainWrap.invItmTaxWprList) {
            if (invTax.isSelected) {
                if (flag) {
                    tempContId = null;
                    break;
                }
                flag = true;
                tempContId = invTax.containerId;
            }
        }
        addTariff.Container_Detail__c = tempContId;
        addTariff.Invoice__c = invMainWrap.invoice.Id;
        return null;
    }

    public PageReference cancel () {
        showPopup = false;
        showAddTaxBtn = false;
        return null;
    } // End method
    // Tax name, percent, amout wrapper
    public with sharing class TaxDetails {
        public String taxName   {get; set;}
        public Decimal percent  {get; set;}
        public Decimal taxAmt   {get; set;}
    }

    // Tax wrapper
    public with sharing class Tax {
        public List<TaxDetails> taxDetailList;
        public Decimal taxAmt;
    }

    // InvoiceItemTax wrapper
    public with sharing class InvItmWithTaxWrp {
        public String container                             {get; set;}
        public String containerId                           {get; set;}
        public Decimal amount                               {get; set;}
        public Decimal taxAmt                               {get; set;}
        public Decimal totAmt                               {get; set;}
        public Invoice_Item__c invItm                       {get; set;}
        public Boolean isSelected                           {get; set;}
        public List<TaxDetails> taxInfoList                 {get; set;}
        public List<Invoice_Tax_Item__c> invTaxItmList      {get; set;}
        public Additional_Tariff__c addTariff               {get; set;}

        public InvItmWithTaxWrp (Boolean pIsSelected, String pContainer, Decimal pAmount,
                                Decimal pTaxAmt, Decimal pTotAmt,
                                List<TaxDetails> pTaxInfoList, String pContainerId) {
            this.isSelected = pIsSelected;
            this.container = pContainer;
            this.amount = pAmount;
            this.taxAmt = pTaxAmt;
            this.totAmt = pTotAmt;
            this.taxInfoList = ptaxInfoList;
            this.containerId = pContainerId;
        } // End constructor
    }

    public with sharing class InvoiceAndItemWrp {
        public Invoice__c invoice                       {get; set;}
        public List<InvItmWithTaxWrp> invItmTaxWprList  {get; set;}
    }
}