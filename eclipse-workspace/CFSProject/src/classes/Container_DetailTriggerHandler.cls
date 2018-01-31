/**
 * Description: This is a trigger handler for container details object's trigger
 *
 *    Author           Date (mm-dd-yyyy)  Version    Changelog
 * Siddharth Pandit    29/11/2017           1.0      Inital draft
 **/
public with sharing class Container_DetailTriggerHandler {
    // A method that finds duplicate containers and throw error
    public static void checkDuplicateContainers_Insert (List<Container_Detail__c> pContList) {
        Set<String> dupCont = new Set<String> (); // Duplicate container no. (row) in the CSV
        Set<String> containerNoSet = new Set<String> ();
        for (Container_Detail__c container : pContList) {
            if (containerNoSet.contains (container.Name))
                dupCont.add (container.Name);
                containerNoSet.add (container.Name);
        } // End for

        System.debug ('containerNoSet ==> '+ containerNoSet);
        Set<String> dupContainerSet = new Set<String> ();
        for (Container_Detail__c aCont : [SELECT Id, Name, Gate_Out_Date__c
                                        FROM Container_Detail__c
                                        WHERE Name IN : containerNoSet
                                        AND Gate_Out_Date__c = null]) {
            dupContainerSet.add (aCont.Name);
        }

        System.debug ('dupContainerSet ==> '+ dupContainerSet);
        for (Container_Detail__c cont : pContList) {
            if (dupContainerSet.contains (cont.Name) ||
                dupCont.contains (cont.Name)) {
                cont.addError (cont.Name + ' is not yet out from the empty yard!' +
                    ' or repeatedly added in the CSV.');
            } // End if
        } // End for
    } // End method

    public static void checkDuplicateContainers_Update (List<Container_Detail__c> pContList) {
        Set<String> containerNoSet = new Set<String> ();
        for (Container_Detail__c container : pContList) {
                containerNoSet.add (container.Name);
        } // End for

        System.debug ('containerNoSet ==> '+ containerNoSet);
        Map<String, String> contIdNameMap = new Map<String, String> ();
        for (Container_Detail__c aCont : [SELECT Id, Name, Gate_Out_Date__c
                                        FROM Container_Detail__c
                                        WHERE Name IN : containerNoSet
                                        AND Gate_Out_Date__c = null]) {
            contIdNameMap.put (aCont.Name, aCont.Id);
        }

        System.debug ('contIdNameMap ==> '+ contIdNameMap);
        for (Container_Detail__c cont : pContList) {
            if (contIdNameMap.containsKey (cont.Name) &&
                contIdNameMap.get (cont.Name) != cont.Id) {
                cont.addError (cont.Name + ' is not yet out from the empty yard!');
            } // End if
        } // End for
    } // End method
}