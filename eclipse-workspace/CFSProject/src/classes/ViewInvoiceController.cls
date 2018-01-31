public with sharing class ViewInvoiceController {
    public InvoiceAndItemWrp invMainWrap                        {get; set;}
    public String selectedTaxGroup                              {get; set;}
    public Additional_Tariff__c addTariff                       {get; set;}
    public Boolean showPopup                                    {get; set;}
    public Boolean showAddTaxBtn                                {get; set;}
    public Boolean showInvAddTax                                {get; set;}
    public Map<String, Map<String, Integer>> contTariffCountMap {get; set;} // Sid to use

    // Variables
    private static Id recordId;
    private static final String INVOICEOBJ          = 'Invoice__c';
    private static final String INVOICEITMOBJ       = 'Invoice_Item__c';
    private static final String INVOICEITMTAXOBJ    = 'Invoice_Tax_Items__r';
    private static Map<String, List<Invoice_Tax_Item__c>> contNameTaxItmListMap;
    private static Map<String, List<Additional_Invoice_Tax_Item__c>> contNameAddTaxItmListMap;
    private static Map<String, Decimal> contIdAddAmtMap;
    private static Map<String, Decimal> contIdAddTaxAmtMap;
    private static Boolean showInvAddTable;
    private static List<Additional_Tariff__c> invAddTariffMap;

    // Constructor
    public viewInvoiceController () {
        showAddTaxBtn = false;
        showInvAddTax = false;
    }

    public InvoiceAndItemWrp getInvoiceData () {
        recordId = apexpages.currentpage().getparameters().get ('invId');
        invMainWrap = new InvoiceAndItemWrp ();
        List<Invoice__c> invObjToReturn = fetchInvoice (recordId);
        if (invObjToReturn.size () == 0) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,
                                'No Invoice Found!'));
            return null;
        }
        invMainWrap.invoice = invObjToReturn.get (0);
        invMainWrap.invItmTaxWprList = fetchInvoiceItemAndTaxItm (recordId);
       // contTariffCountMap = retrieveTariffCountMap (invMainWrap.invItmTaxWprList);
        invMainWrap.invAddTariffList = invAddTariffMap;
        showInvAddTax = showInvAddTable;
        System.debug ('contTariffCountMap ==> '+ contTariffCountMap);
       // invMainWrap = invWrp; // assigning for other variables
        return invMainWrap;
    }
    // A method to fetch invoice details
    private static List<Invoice__c> fetchInvoice (String invId) {
        List<Schema.FieldSetMember> fieldSet = 
                    SObjectType.Invoice__c.FieldSets.ViewInvoice.getFields();
        String queryStr = UtilityGeneral.buildQuery (fieldSet, INVOICEOBJ);
        queryStr += ' WHERE Id = ' + UtilityGeneral.wrapInSingleQuotes (invId);
        queryStr += ' LIMIT 1';
        return Database.query (queryStr);
    } // End method

    // A method to add a subquery
    private static String buildFinalQuery (String pSubQry, String pInvId) {
        return ' SELECT Id, Amount__c, Container_No__c, Invoice_No__c,' +
                        'Container_No__r.Name, Tax_Amount__c, Tax_Group__c,' +
                        'Quantity__c, Total_Amount__c, Rate__c, ' +
                        'Tariff_Rate_No__r.Tariff_Head__r.Name, ' +
                        '(' + pSubQry + ' ) FROM ' + INVOICEITMOBJ +
                ' WHERE Invoice_No__c ='+ UtilityGeneral.wrapInSingleQuotes (pInvId) +
                ' ORDER BY Container_No__c';
    }// End method

    // A method to fetch invoice details
    private static List<InvItmWithTaxWrp> fetchInvoiceItemAndTaxItm (String invId) {
        Map<String, Integer> tariffHeadCount = new Map<String, Integer> ();
        List<InvItmWithTaxWrp> lstInvItmWithTax = new List<InvItmWithTaxWrp> ();
        Map<String, Decimal> contNameAmtMap = new Map<String, Decimal> ();
        contNameTaxItmListMap = new Map<String, List<Invoice_Tax_Item__c>> ();
        List<InvItmWithTaxWrp> listWprToReturn = new List<InvItmWithTaxWrp> ();
        Map<String, List<Invoice_Item__c>> itmMap = new Map<String, List<Invoice_Item__c>> ();
        Map<String, List<Additional_Tariff__c>> addTariffMap = fetchAddTariffMap (recordId);
        List<Schema.FieldSetMember> invTaxItmFields = 
                    SObjectType.Invoice_Tax_Item__c.FieldSets.ViewInvoiceTaxItems.getFields();
        String subQuery = UtilityGeneral.buildQuery (invTaxItmFields, INVOICEITMTAXOBJ);
        subQuery += ' ORDER BY Name';
        String queryStr = buildFinalQuery (subQuery, invId);
        String prevContainer, prevContainerName; Decimal addAmt, addTaxAmt;
        invAddTariffMap = addTariffMap.containsKey (null) ?
                    addTariffMap.get (null) : null; // Additional tariff for invoice
        showInvAddTable = invAddTariffMap != null;
        for (Invoice_Item__c invItm : Database.query (queryStr)) {
            if (!itmMap.containsKey (invItm.Container_No__c))
                itmMap.put (invItm.Container_No__c, new List<Invoice_Item__c> ());
                itmMap.get (invItm.Container_No__c).add (invItm);
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
                addAmt = !contIdAddAmtMap.containsKey (prevContainer) ? 0 :
                            contIdAddAmtMap.get (prevContainer);
                addTaxAmt = !contIdAddTaxAmtMap.containsKey (prevContainer) ? 0 :
                            contIdAddTaxAmtMap.get (prevContainer);
                String tariffHeadName = invItm.Tariff_Rate_No__r.Tariff_Head__r.Name;
                if (!tariffHeadCount.containsKey (tariffHeadName))
                    tariffHeadCount.put (tariffHeadName, 1);
                    if (String.isBlank (prevContainer) || 
                        prevContainer == invItm.Container_No__c) {
                        Integer count = tariffHeadCount.get (tariffHeadName) + 1;
                        tariffHeadCount.put (tariffHeadName, count);
                    }

                if (String.isNotBlank (prevContainer) &&
                    prevContainer != invItm.Container_No__c) {
                        System.debug ('tariffHeadCount ==> '+ tariffHeadCount);
                Tax adTx;
                if (!contNameAddTaxItmListMap.isEmpty () &&
                    contNameAddTaxItmListMap.containsKey (prevContainer))
                    adTx = retrieveTaxInfo (contNameAddTaxItmListMap.get (prevContainer));
                    List<TaxDetails> txList = adTx != null? adTx.taxDetailList : null;
                    Decimal adTaxAmt =  adTx != null? adTx.taxAmt : 0;
                    Tax taxInfo = retrieveTaxInfo (contNameTaxItmListMap.get (prevContainer));
                    lstInvItmWithTax.add (new InvItmWithTaxWrp (false, prevContainerName,
                                        contNameAmtMap.get (prevContainer) + addAmt,
                                        taxInfo.taxAmt + addTaxAmt,
                                        contNameAmtMap.get (prevContainer) + addAmt +
                                        taxInfo.taxAmt + addTaxAmt,
                                        addTariffMap.get (prevContainer),
                                        taxInfo.taxDetailList, prevContainer,
                                        itmMap.get (prevContainer), txList, adTaxAmt,
                                        tariffHeadCount));
                    tariffHeadCount = new Map<String, Integer> ();
                    System.debug ('tariffHeadCount ==> '+ tariffHeadCount);
                }
                prevContainer = invItm.Container_No__c;
                prevContainerName = invItm.Container_No__r.Name;
        } // End for

        Tax adTx;
        if (!contNameAddTaxItmListMap.isEmpty () &&
            contNameAddTaxItmListMap.containsKey (prevContainer))
            adTx = retrieveTaxInfo (contNameAddTaxItmListMap.get (prevContainer));
            List<TaxDetails> txList = adTx != null? adTx.taxDetailList : null;
            Decimal adTaxAmt =  adTx != null? adTx.taxAmt : 0;
        Tax taxInfo = retrieveTaxInfo (contNameTaxItmListMap.get (prevContainer));
        lstInvItmWithTax.add (new InvItmWithTaxWrp (false, prevContainerName,
                            contNameAmtMap.get (prevContainer) + addAmt,
                            taxInfo.taxAmt + addTaxAmt,
                            contNameAmtMap.get (prevContainer) + taxInfo.taxAmt + addTaxAmt +
                            addAmt, addTariffMap.get (prevContainer),
                            taxInfo.taxDetailList, prevContainer, itmMap.get (prevContainer),
                            txList, adTaxAmt, tariffHeadCount));
        System.debug ('lstInvItmWithTax ==> '+ lstInvItmWithTax);
        return lstInvItmWithTax;
    } // End method

    // A method to calculate total tax for invoice items
    private static Tax retrieveTaxInfo (List<Sobject> pTaxItmList) {
        Tax tax= new Tax ();
        tax.taxAmt = 0;
        tax.taxDetailList = new List<TaxDetails> ();
        Map<String, Decimal> taxNamePercentMap = new Map<String, Decimal> ();
        Map<String, Decimal> taxNameAmtMap = new Map<String, Decimal> ();
        for (Sobject aTaxItm : pTaxItmList) {
            String taxName = String.valueOf (aTaxItm.get ('Tax_Name__c'));
            Decimal taxAmt = (Decimal)aTaxItm.get ('Tax_Amount__c');
            if (!taxNameAmtMap.containsKey (taxName))
                taxNameAmtMap.put (taxName, 0);
                Decimal amt = taxNameAmtMap.get (taxName) + taxAmt;
                taxNameAmtMap.put (taxName, amt);
                tax.taxAmt += taxAmt;
                taxNamePercentMap.put (taxName, (Decimal) aTaxItm.get ('Tax_Rate__c'));
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

    // A method to fetch additional tariff data
    private static Map<String, List<Additional_Tariff__c>> fetchAddTariffMap (Id pInvId) {
        contNameAddTaxItmListMap = new Map<String, List<Additional_Invoice_Tax_Item__c>> ();
        contIdAddAmtMap = new Map<String, Decimal> ();
        contIdAddTaxAmtMap = new Map<String, Decimal> ();
        Map<String, List<Additional_Tariff__c>> contIdAddTariffMap =
                                    new Map<String, List<Additional_Tariff__c>> ();
        for (Additional_Tariff__c addTariff : [SELECT Id, Amount__c, Container_Detail__c, 
                                                        Quantity__c, Rate__c, Tariff_Head__c,
                                                        Additional_Tax_Amount__c,
                                                        Total_Additional_Amount__c,
                                                        (SELECT Tax_Amount__c, Tax_Name__c,
                                                                Tax_Rate__c, Tax_Type__c
                                                        FROM Additional_Invoice_Tax_Items__r),
                                                        Tax_Group__c, Tariff_Head__r.Name
                                                FROM Additional_Tariff__c
                                                WHERE Invoice__c =: pInvId]) {
            if (!contIdAddTariffMap.containsKey (addTariff.Container_Detail__c)) {
                contIdAddTariffMap.put (addTariff.Container_Detail__c,
                                        new List<Additional_Tariff__c> ());
                contIdAddAmtMap.put (addTariff.Container_Detail__c, 0);
                contIdAddTaxAmtMap.put (addTariff.Container_Detail__c, 0);
            }
                contIdAddTariffMap.get (addTariff.Container_Detail__c).add (addTariff);

                // Amount
                Decimal amt = contIdAddAmtMap.get (addTariff.Container_Detail__c) + 
                            addTariff.Amount__c;
                contIdAddAmtMap.put (addTariff.Container_Detail__c, amt);
                // Tax amount
                Decimal taxAmt = contIdAddTaxAmtMap.get (addTariff.Container_Detail__c) + 
                            addTariff.Additional_Tax_Amount__c;
                contIdAddTaxAmtMap.put (addTariff.Container_Detail__c, taxAmt);

            if (!contNameAddTaxItmListMap.containsKey (addTariff.Container_Detail__c))
                contNameAddTaxItmListMap.put (addTariff.Container_Detail__c,
                                        new List<Additional_Invoice_Tax_Item__c> ());
                contNameAddTaxItmListMap.get (addTariff.Container_Detail__c)
                            .addAll (addTariff.Additional_Invoice_Tax_Items__r);
        }
        return contIdAddTariffMap;
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
        createAdditaionTaxItm (addTariff); // Adding tax for additional tariff
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
                    tempContId = null; showInvAddTax = true;
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

    // A method to add additional tariff tax
    private static void createAdditaionTaxItm (Additional_Tariff__c pAddTariff) {
        List<Additional_Invoice_Tax_Item__c> addTaxItmList = 
                            new List<Additional_Invoice_Tax_Item__c> ();
        for (Tax_type__c taxType : [SELECT Id, Tax_Percentage__c
                                    FROM Tax_type__c
                                    WHERE Tax_Group__c =: pAddTariff.Tax_Group__c]) {
            Additional_Invoice_Tax_Item__c addTaxItm = new Additional_Invoice_Tax_Item__c ();
            addTaxItm.Tax_Type__c = taxType.Id;
            addTaxItm.Additional_Tariff__c = pAddTariff.Id;
            addTaxItm.Tax_Rate__c = taxType.Tax_Percentage__c;
            addTaxItmList.add (addTaxItm);
        } // End for
        if (!addTaxItmList.isEmpty ())
            insert addTaxItmList;
    } // End method

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

    // A method to fill map of container Id and TariffHead count
    // Sid to fill
 /*   private static Map<String, Map<String, Integer>> retrieveTariffCountMap 
                                                (List<InvItmWithTaxWrp> pInvItmTaxWprList) {
        Map<String, Map<String, Integer>> mapToReturn = new Map<String, Map<String, Integer>> ();
        for (InvItmWithTaxWrp wrp : pInvItmTaxWprList) {
            if (!mapToReturn.containsKey (wrp.container))
                mapToReturn.put (wrp.container, new Map<String, Integer> ());
                Map<String, Integer> tariffHeadCountMap = new Map<String, Integer> ();
                for (String key : retrieveTariffHeadCount (wrp.invItmList).keySet ()) {
                    if (!tariffHeadCountMap.containsKey (key))
                        tariffHeadCountMap.put (key, 0);
                        Integer rowCount = tariffHeadCountMap.get (key) + 1;
                        tariffHeadCountMap.put (key, rowCount);
                }
                if (wrp.itmAddTariffList != null && !wrp.itmAddTariffList.isEmpty ()) {
                    for (String key : retrieveAddTariffHeadCount (wrp.itmAddTariffList).keySet ()) {
                        if (!tariffHeadCountMap.containsKey (key))
                            tariffHeadCountMap.put (key, 0);
                            Integer rowCount = tariffHeadCountMap.get (key) + 1;
                            tariffHeadCountMap.put (key, rowCount);
                    } // End for
                } // End if
                mapToReturn.get (wrp.container).putAll (tariffHeadCountMap);
        } // End for
        return mapToReturn;
    }

    // A method that returns tariffhead name and count from invoice item
    private static Map<String, Integer> retrieveTariffHeadCount (List<Invoice_Item__c>
                                                                    pInvItmList) {
        Map<String, Integer> tariffHeadCountMap = new Map<String, Integer> ();
        for (Invoice_Item__c invItm : pInvItmList) {
            if (!tariffHeadCountMap.containsKey (invItm.Tariff_Rate_No__r.Tariff_Head__r.Name))
                tariffHeadCountMap.put (invItm.Tariff_Rate_No__r.Tariff_Head__r.Name, 0);
                Integer count = 
                    tariffHeadCountMap.get (invItm.Tariff_Rate_No__r.Tariff_Head__r.Name) + 1;
                tariffHeadCountMap.put (invItm.Tariff_Rate_No__r.Tariff_Head__r.Name, count);
        }
        return tariffHeadCountMap;
    }

    // A method that returns tariffhead name and count from additaion tariff
     private static Map<String, Integer> retrieveAddTariffHeadCount (List<Additional_Tariff__c>
                                                                    pAddTariffList) {
        Map<String, Integer> tariffHeadCountMap = new Map<String, Integer> ();
        for (Additional_Tariff__c addTariff : pAddTariffList) {
            if (!tariffHeadCountMap.containsKey (addTariff.Tariff_Head__r.Name))
                tariffHeadCountMap.put (addTariff.Tariff_Head__r.Name, 0);
                Integer count = tariffHeadCountMap.get (addTariff.Tariff_Head__r.Name) + 1;
                tariffHeadCountMap.put (addTariff.Tariff_Head__r.Name, count);
        }
        return tariffHeadCountMap;
    } */

    // InvoiceItemTax wrapper
    public with sharing class InvItmWithTaxWrp {
        public Boolean isSelected                                   {get; set;}
        public String container                                     {get; set;}
        public Decimal amount                                       {get; set;}
        public Decimal taxAmt                                       {get; set;}
        public Decimal totAmt                                       {get; set;}
        public List<Additional_Tariff__c> itmAddTariffList          {get; set;}
        public List<TaxDetails> taxInfoList                         {get; set;}
        public String containerId                                   {get; set;}
       // public List<Invoice_Tax_Item__c> invTaxItmList              {get; set;}
        public List<Invoice_Item__c> invItmList                     {get; set;}
        public List<TaxDetails> addTaxInfoList                      {get; set;}
        public Decimal addTaxAmt                                    {get; set;}
        public Map<String, Integer> tariffHeadCountMap              {get; set;}

        public InvItmWithTaxWrp (Boolean pIsSelected, String pContainer, Decimal pAmount,
                                Decimal pTaxAmt, Decimal pTotAmt,
                                List<Additional_Tariff__c> pItmAddTariffList,
                                List<TaxDetails> pTaxInfoList, String pContainerId,
                                List<Invoice_Item__c> pInvItmList,
                                List<TaxDetails> pAddTaxInfoList, Decimal pAddTaxAmt,
                                Map<String, Integer> pTariffHeadCountMap) {
            this.isSelected = pIsSelected;
            this.container = pContainer;
            this.amount = pAmount;
            this.taxAmt = pTaxAmt;
            this.totAmt = pTotAmt;
            this.itmAddTariffList = pItmAddTariffList;
            this.taxInfoList = ptaxInfoList;
            this.containerId = pContainerId;
            this.invItmList = pInvItmList;
            this.addTaxInfoList = pAddTaxInfoList;
            this.addTaxAmt = pAddTaxAmt;
            this.tariffHeadCountMap = pTariffHeadCountMap;
        } // End constructor
    }

    public with sharing class InvoiceAndItemWrp {
        public Invoice__c invoice                           {get; set;}
        public List<InvItmWithTaxWrp> invItmTaxWprList      {get; set;}
        public List<Additional_Tariff__c> invAddTariffList  {get; set;}
    }
}