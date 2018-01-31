/**
 * Description: This is a utility class that contains static methods to use as helper functions
 * 
 **/
public with sharing class CreateInvoiceUtil {
    private Sobject sobj;
    private static Set<String> contSet;
    private static CreateInvoiceController contrClass;

    // Static variables
    private static Revenue_Tariff_Configure__c revConfig;

    // Constructor
    public CreateInvoiceUtil(CreateInvoiceController controller) {
        contrClass = controller;
        Id recordId = apexpages.currentpage().getparameters().get('jobOrdId');
        if (recordId.getSObjectType().getDescribe().getName() == 'Job_Order__c')
            sobj = [SELECT Id, Combination_Key__c FROM Job_Order__c 
                    WHERE Id =:recordId LIMIT 1];
        else
            sobj = [SELECT Id, Combination_Key__c, IGM_NO__c FROM Document_Detail__c 
                    WHERE Id =:recordId LIMIT 1];
        System.debug ('sobj ==> '+ sobj);
        System.debug ('contSet ==> '+ contSet);
    }

    // A method to create invoice
    public static Invoice__c insertInvoice (Sobject sObj) {
        Invoice__c invoice;
        if (sObj != null) {
            String combKey = (String) sObj.get ('Combination_Key__c');
            revConfig = retrieveRevTariff (combKey);
            invoice = new Invoice__c ();
            if (String.valueOf (sObj.getSobjectType ()) == 'Document_Detail__c') {
                invoice.Item_No__c = String.valueOf (sObj.get ('Id'));
                invoice.IGM_NO__c = String.valueOf (sObj.get ('IGM_NO__c'));
            } else {
                invoice.Job_Order__c = String.valueOf (sObj.get ('Id'));
                invoice.RecordTypeId = '0127F000000x1cK';
            }
            invoice.Invoice_Date__c = Datetime.now ();
            invoice.Contractor__c = revConfig.Id;
            System.debug ('invoice ==> '+ invoice);
            insert invoice;
        } // End if
        return invoice;
    }

    // Fetching all the rates for the Revenue-Tariff-Configue
    private static Map<Revenue_Tariff_Rate__c, List<Tax_type__c>>
                     fetchTarriffRates (Revenue_Tariff_Configure__c revConfig) {
        Map<String, List<Revenue_Tariff_Rate__c>> txGrpIdListObjMap =
                                            new Map<String, List<Revenue_Tariff_Rate__c>> ();
        Map<Revenue_Tariff_Rate__c, List<Tax_type__c>> revTerListTaxTypeMap = 
            new Map<Revenue_Tariff_Rate__c, List<Tax_type__c>> ();
        for (Revenue_Tariff_Rate__c revTarriff : [SELECT Id, From__c, To__c, Tax_Group__c,
                                                        Rate__c,
                                                        Tariff_Head__r.Activity_type__c
                                                    FROM Revenue_Tariff_Rate__c
                                                    WHERE For_Contract__c = : revConfig.Id]) {
            revTerListTaxTypeMap.put (revTarriff, new List<Tax_type__c> ());
            if (!txGrpIdListObjMap.containsKey (revTarriff.Tax_Group__c))
                txGrpIdListObjMap.put (revTarriff.Tax_Group__c,
                                        new List<Revenue_Tariff_Rate__c> ());
                txGrpIdListObjMap.get (revTarriff.Tax_Group__c).add (revTarriff);
        } // End for

        for (Tax_type__c txType : [SELECT Id, Name, Tax_Percentage__c, Tax_Group__c
                                    FROM Tax_type__c
                                    WHERE Tax_Group__c IN : txGrpIdListObjMap.keySet ()]) {
            for (Revenue_Tariff_Rate__c revTar : txGrpIdListObjMap.get (txType.Tax_Group__c)) {
                if (revTerListTaxTypeMap.containsKey (revTar))
                    revTerListTaxTypeMap.get (revTar).add (txType);
            }
        }
        return revTerListTaxTypeMap;
    }

    // A method that returns a matching Revenue Tariff Configuration. If no matching
    // configuration is found then it will return General configuration
    private static Revenue_Tariff_Configure__c retrieveRevTariff (String pCombinationkey) {
        List<Revenue_Tariff_Configure__c> listTariffConfig = 
                        [SELECT Id
                        FROM Revenue_Tariff_Configure__c
                        WHERE Combination_Key__c =: pCombinationkey];
        if (listTariffConfig.isEmpty ())
            listTariffConfig = [SELECT Id
                                FROM Revenue_Tariff_Configure__c
                                WHERE Name = 'General'];
        return listTariffConfig.get (0);
    } // End method

    // A method to calculate no of days container stayed in the CFS
    private static Map<String, Integer> retrieveNoOfDays (List<Container_Detail__c> pContList) {
        Map<String, Integer> contIdDaysMap = new Map<String, Integer> ();
        for (Container_Detail__c contDetail : pContList) {
            contIdDaysMap.put (contDetail.Id, getDays (contDetail));
        } // End for
        return contIdDaysMap;
    } // End method

    // A method that returns no of days
    private static Integer getDays (Container_Detail__c pCont) {
        Date inDate = pCont.Gate_In_Date__c.date ().addDays (-1);
        Integer days = inDate.daysBetween (pCont.Gate_Out_Date__c.date());
        if (days == 0) return 1;
        else 
        return days;
    }

    // A method to append selected containers set in the query
    private static String appendSelContainers (String pQrStr, String pContIds) {
        return pQrStr + ' AND Id IN '+ pContIds;
    }
    // A method to insert invoice items
    public static void createInvoiceItems (Invoice__c pInvoice, String selContSet) {
        List<Invoice_Item__c> invItmListToInsert = new List<Invoice_Item__c> ();
        Map<String, List<Tax_type__c>> invItmListTaxMap =
                                        new Map<String, List<Tax_type__c>> ();
        String queryStr = appendSelContainers (buildQuery (pInvoice), selContSet);
        System.debug ('queryStr ==> '+ queryStr);
        List<Container_Detail__c> contList =
                            Database.query (queryStr);
        Map<String, Integer> contIdDays = retrieveNoOfDays (contList);
        System.debug ('contIdDays ==> '+ contIdDays);
        Map<Revenue_Tariff_Rate__c, List<Tax_type__c>> revTarListTaxMap =
                                                fetchTarriffRates (revConfig);
        System.debug ('revTarListTaxMap ==> '+ revTarListTaxMap);
        for (String contNo : contIdDays.keySet ()) {
            Integer days = contIdDays.get (contNo);
            for (Revenue_Tariff_Rate__c revTar : revTarListTaxMap.keySet ()) {
                String key = contNo +'-'+ revTar.Rate__c;
                Invoice_Item__c invItm = new Invoice_Item__c ();
                invItm.Invoice_No__c = pInvoice.Id;
                invItm.Tariff_Rate_No__c = revTar.Id;
                invItm.Container_No__c = contNo;
                invItm.Rate__c = revTar.Rate__c;
               /* if (String.isNotBlank (revTar.Tariff_Head__r.Activity_type__c) &&
                    revTar.Tariff_Head__r.Activity_type__c == 'Unit Based') {
                    invItm.Quantity__c = 1;
                    invItmListToInsert.add (invItm);
                }
                else */ if (days > revTar.To__c) {
                    invItm.Quantity__c = revTar.To__c - revTar.From__c;
                    invItmListToInsert.add (invItm);
                } else if (days > revTar.From__c) {
                    invItm.Quantity__c = days - revTar.From__c;
                    invItmListToInsert.add (invItm);
                }
                invItmListTaxMap.put (key, revTarListTaxMap.get (revTar));
            } // End for
        } // End main for
        if (!invItmListToInsert.isEmpty ()) {
            insert invItmListToInsert;
            insertTaxItm (fillInvItmMap (invItmListToInsert, invItmListTaxMap));
        } // End if
    }

    // A method that will prepare map of Invoice Item and list Tax Types
    private static Map<Invoice_Item__c, List<Tax_type__c>> 
                                fillInvItmMap (List<Invoice_Item__c> pInvItm,
                                        Map<String, List<Tax_type__c>> pKeyTaxListMap) {
        Map<Invoice_Item__c, List<Tax_type__c>> invListTaxMapToReturn = 
                                new Map<Invoice_Item__c, List<Tax_type__c>> ();
        for (Invoice_Item__c invItm : pInvItm) {
            String key = invItm.Container_No__c +'-'+invItm.Rate__c;
            if (pKeyTaxListMap.containsKey (key))
                invListTaxMapToReturn.put (invItm, pKeyTaxListMap.get (key));
        }
        return invListTaxMapToReturn;
    }

    // A method to create Invoice Tax Item
    private static void insertTaxItm ( Map<Invoice_Item__c, List<Tax_type__c>> invItmTaxList) {
        List<Invoice_Tax_Item__c> listInvTax = new List<Invoice_Tax_Item__c> ();
        for (Invoice_Item__c invItm : invItmTaxList.keySet ()) {
            for (Tax_type__c taxType : invItmTaxList.get (invItm)) {
                Invoice_Tax_Item__c invTxItm = new Invoice_Tax_Item__c ();
                invTxItm.Tax_type__c = taxType.Id;
                invTxItm.Invoice_Item__c = invItm.Id;
                listInvTax.add (invTxItm);
            } // End inner for
        } // End outer for
        if (!listInvTax.isEmpty ())
            insert listInvTax;
    }

    // A method to build SOQL
    private static String buildQuery (Invoice__c pInvoice) {
        System.debug ('pInvoice ==> '+ pInvoice.Job_Order__c);
        if (pInvoice.RecordTypeId == '0127F000000x1cK') // Checking empty invoice record type
            return 'SELECT Id, Gate_In_Date__c, Gate_Out_Date__c ' +
                'FROM Container_Detail__c WHERE Job_Order_NO__c = ' + 
                    UtilityGeneral.wrapInSingleQuotes (pInvoice.Job_Order__c);
        else /*if (pRecordTypeName == 'Empty Invoice') */
            return 'SELECT Id, Gate_In_Date__c, Gate_Out_Date__c ' +
                'FROM Container_Detail__c WHERE Item_No__c =: '+pInvoice.Item_No__c; 
        //return null;
    }
    
}