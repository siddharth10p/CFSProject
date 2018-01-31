public with sharing class UpdateInvoiceNoHandler {
    public static void onContainerdetails(List<Invoice_Item__c> invItmList) {
        Map<Id, Id> conInvMap = new Map<Id, Id> ();
        for (Invoice_Item__c inv : invItmList) {
            conInvMap.put (inv.Container_No__c, inv.Invoice_No__c);
        }
        List<Container_Detail__c> conListForUpdate = New List<Container_Detail__c> ();
        for (Container_Detail__c con: [SELECT Id, Invoice_No__c
                                        FROM Container_Detail__c
                                        WHERE Id IN :conInvMap.keyset()]) {
            con.Invoice_No__c = conInvMap.get (con.Id);
            conListForUpdate.add (con);
        }
        if (conListForUpdate.size () > 0)
            update conListForUpdate;
    }
}