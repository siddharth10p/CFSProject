/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * TDD: (Connecting MQIs to Opportunities):
 * https://docs.google.com/document/d/1m0q2hXBG9iMNWxxnZfsh1UQdnuDyc7PuaIdfug1rGow/edit?
        pli=1#heading=h.uq6hzdnsihmp

 * TDD (Determining Product and Line of Business Responsible for MQI):
 * https://docs.google.com/document/d/1m0q2hXBG9iMNWxxnZfsh1UQdnuDyc7PuaIdfug1rGow/edit?
    %20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20pli=1#heading=h.ni0gvo2hoe7c
 **/
@isTest
private class TestUpdateOpptyLookupOnCustPathBatch {

    static testMethod void coverUpdateOpptyLookupOnCustPathBatch () {
        // Create data
        UtilityGeneral.setUpTestData ();
        Test.startTest();
        UpdateOpptyLookupOnCustPathBatch updateCustPath = new UpdateOpptyLookupOnCustPathBatch();
        string schTime = '0 0 * * 1-12 ? *';
        system.schedule('UpdateOpptyLookupOnCustPathBatch', schTime, updateCustPath);

        Database.executeBatch (updateCustPath, 200);
    	Test.stopTest();
    Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];
    	// Assertion
    	Set<String> conIdSet = new Set<String> ();
    	for (p2s_base1__CustomerPath__c custPathInstance : [SELECT Id, p2s_base1__ToLifecycleStage__c,
                                                                p2s_base1__Opportunity__c,
                                                                p2s_base1__Contact__c
                                                        FROM p2s_base1__CustomerPath__c
                                                        WHERE p2s_base1__Contact__c <> null
                                                        ORDER BY p2s_base1__TransitionDateTime__c
                                                        DESC]) {
        if (UtilityGeneral.STAGE_RECYCLED.equals (custPathInstance.p2s_base1__ToLifecycleStage__c))
            conIdSet.add (custPathInstance.p2s_base1__Contact__c);
        if (!conIdSet.contains (custPathInstance.p2s_base1__Contact__c))
            System.assertEquals (oppty.Id, custPathInstance.p2s_base1__Opportunity__c);
        else
            System.assertEquals (null, custPathInstance.p2s_base1__Opportunity__c);
        } // End for
    } // End method

    // A method to cover populate MQI data trigger
    static testMethod void coverPopulateMQITriggerHandler () {
        // Create data
    /*    UtilityGeneral.setUpTestData ();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Contact conInstance = new Contact (Last_Product_Interest__c = 'Test Prod Int',
                                Last_Product_Interest_Family__c = 'Prod Int Family',
                                Last_Lead_Activity_Detail__c = 'Fast Track',
                                Last_Form_Fill_Web_Page__c = 'RISI Test Web',
                                Id = con.Id);
        update conInstance;
        p2s_base1__CustomerPath__c custPath = new p2s_base1__CustomerPath__c (
                                p2s_base1__Contact__c = conInstance.Id,
                                p2s_base1__ToLifecycleStage__c = 'Marketing Qualified Instance',
                                p2s_base1__FromLifecycleStage__c = '',
                                p2s_base1__TransitionDateTime__c = Date.today());
        insert custPath;

        Lead leadInst = new Lead (LastName= 'Test', Company ='Test Company',
                                Email = 'test@perkuto.com',
                                Last_Product_Interest__c = 'Test Prod Int2',
                                Last_Product_Interest_Family__c = 'Prod Int Family2',
                                Last_Lead_Activity_Detail__c = 'Fast Track2',
                                Last_Form_Fill_Web_Page__c = 'RISI Test Web2');
        insert leadInst;


        p2s_base1__CustomerPath__c custPath2 = new p2s_base1__CustomerPath__c (
                                p2s_base1__Lead__c = leadInst.Id,
                                p2s_base1__ToLifecycleStage__c = 'Marketing Qualified Instance',
                                p2s_base1__FromLifecycleStage__c = '',
                                p2s_base1__TransitionDateTime__c = Date.today());
        insert custPath2;

        // Assertion
        for (p2s_base1__CustomerPath__c custPathExist : [SELECT Id, Product_Interest__c,
                                                            Product_Interest_Family__c,
                                                            Lead_Activity_Detail__c,
                                                            Form_Fill_Web_Page__c,
                                                            p2s_base1__Contact__c,
                                                            p2s_base1__Lead__c
                                                    FROM p2s_base1__CustomerPath__c]) {
            if (custPathExist.Id.equals (custPath.Id)) {
                System.assertEquals (conInstance.Last_Product_Interest__c, 
                            custPathExist.Product_Interest__c);
                System.assertEquals (conInstance.Last_Product_Interest_Family__c, 
                            custPathExist.Product_Interest_Family__c);
                System.assertEquals (conInstance.Last_Lead_Activity_Detail__c, 
                            custPathExist.Lead_Activity_Detail__c);
                System.assertEquals (conInstance.Last_Form_Fill_Web_Page__c, 
                            custPathExist.Form_Fill_Web_Page__c);
            } 
            if (custPathExist.Id.equals (custPath2.Id)) {
                System.assertEquals (leadInst.Last_Product_Interest__c, 
                            custPathExist.Product_Interest__c);
                System.assertEquals (leadInst.Last_Product_Interest_Family__c, 
                            custPathExist.Product_Interest_Family__c);
                System.assertEquals (leadInst.Last_Lead_Activity_Detail__c, 
                            custPathExist.Lead_Activity_Detail__c);
                System.assertEquals (leadInst.Last_Form_Fill_Web_Page__c, 
                            custPathExist.Form_Fill_Web_Page__c);
            }
        } */
    }
} // End class