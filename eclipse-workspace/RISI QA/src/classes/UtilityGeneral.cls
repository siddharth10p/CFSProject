/**
 * Description: This class contains all utility methods used in other classes / triggers
 *
 *    Author             Date (mm-dd-yyyy)    Version       ChangeLog
 * Siddharth Pandit        07/02/2016          1.0          Initial Draft
 * Siddharth Pandit        08/24/2016          1.1          Add a logic to calculate weekends
 * Siddharth Pandit        05/25/2017          1.2          Add a logic to resolve overstamping
 *                                                          issue. Oppty should be connected on
 *                                                          CPs created before InOpenOppty
 *                                                          transition until Recycle transition
 *
 * TDD: (Connecting MQIs to Opportunities):
 * https://docs.google.com/document/d/1m0q2hXBG9iMNWxxnZfsh1UQdnuDyc7PuaIdfug1rGow/edit?
        pli=1#heading=h.uq6hzdnsihmp
 */
public with sharing class UtilityGeneral {
    // private final variables
    private static final String STR_LABELTXT = 'Label_Text__c';
    private static final String STR_SUBJECT = 'Task_Subject__c';
    private static final String STR_LINEBRK = 'Line_Break__c';
    private static final String STR_FIELDNAME = 'Field_Name__c';
    private static final String STR_ACC = 'Account';
    private static final String STR_NAME = 'Name';
    private static final String STR_INIT = '';
    private static final String STR_NEWLINE = '\n';
    private static final String STR_SPACE = ' ';
    private static final String STR_COMPANY = 'Company';
    private static final String STR_COMMA = ',';
    private static final String OWNER_FIELDNAME = 'OwnerId';
    private static final String ACCISR_FIELDNAME = 'Assigned_ISR__c';
    private static final String STR_ACCNAME = 'Account.Name';
    private static final String ID_FIELDNAME = 'Id';
    private static final String STR_ACCASSIGNISR = 'Account.Assigned_ISR__c';
    private static final String ACCID_FIELDNAME = 'AccountId';
    private static final String STR_FROM = 'FROM';
    private static final String STR_BLANKPREV = 'Blank_Previous_Value__c';
    private static final String STR_BLANKNEXT = 'Blank_Next_Value__c';
    public static final String STAGE_RECYCLED = 'Recycled';
    private static final String STAGE_INOPENOPTY = 'In Open Opportunity';
    public static final String STR_FREETRIAL = 'Free Trial';

    public static Integer BATCH_START_ROWS_LIMIT = 50000000; // Used in batch
    public static Boolean recursive = true;
    public static Boolean recursiveMQI = true;
    public static Boolean puRecursive = true;
    public static Boolean enrichRecursive = true;
    public static Integer count = 0;

    public static void setUpTestData () {
        // Create data
        Account acc = new Account (Name = 'Test Account');
        insert acc;

        Contact con = new Contact (LastName = 'Test Con', AccountId = acc.Id);
        insert con;
        List<p2s_base1__CustomerPath__c> cpListToInsert = new List<p2s_base1__CustomerPath__c> ();
        p2s_base1__CustomerPath__c custPath = new p2s_base1__CustomerPath__c (
                                            p2s_base1__Contact__c = con.Id,
                                            p2s_base1__ToLifecycleStage__c = '',
                                            p2s_base1__FromLifecycleStage__c = 'Name',
                                            p2s_base1__TransitionDateTime__c = Date.today() - 10);
        cpListToInsert.add (custPath);

        p2s_base1__CustomerPath__c custPath2 = new p2s_base1__CustomerPath__c (
                                            p2s_base1__Contact__c = con.Id,
                                            p2s_base1__ToLifecycleStage__c = 'Qualification',
                                            p2s_base1__FromLifecycleStage__c = 'Name',
                                            p2s_base1__TransitionDateTime__c = Date.today() - 5);
        cpListToInsert.add (custPath2);

        p2s_base1__CustomerPath__c custPath3 = new p2s_base1__CustomerPath__c (
                                            p2s_base1__Contact__c = con.Id,
                                            p2s_base1__ToLifecycleStage__c = 'Recycled',
                                            p2s_base1__FromLifecycleStage__c = 'Qualification',
                                            p2s_base1__TransitionDateTime__c = Date.today()- 3);
        cpListToInsert.add (custPath3);

        p2s_base1__CustomerPath__c custPath4 = new p2s_base1__CustomerPath__c (
                                            p2s_base1__Contact__c = con.Id,
                                            p2s_base1__ToLifecycleStage__c = 'Name',
                                            p2s_base1__FromLifecycleStage__c = 'Recycled',
                                            p2s_base1__TransitionDateTime__c = Date.today()- 1);
        cpListToInsert.add (custPath4);

        p2s_base1__CustomerPath__c custPath5 = new p2s_base1__CustomerPath__c (
                                            p2s_base1__Contact__c = con.Id,
                                            p2s_base1__ToLifecycleStage__c = 'SQO',
                                            p2s_base1__FromLifecycleStage__c = 'Name',
                                            p2s_base1__TransitionDateTime__c = Date.today());
        cpListToInsert.add (custPath5);
        Opportunity oppty = new Opportunity (Name='Test', StageName= 'Prospecting', CloseDate = Date.today(),
                                            Revenue_Type__c = 'Subscription - New',
                                            p2s_base1__LifecycleStage__c = 'Name',
                                            Main_Order__c = '123456');
        insert oppty;

        p2s_base1__CustomerPath__c custPath6 = new p2s_base1__CustomerPath__c (
                                            p2s_base1__Contact__c = con.Id,
                                            p2s_base1__ToLifecycleStage__c = 'Name',
                                            p2s_base1__FromLifecycleStage__c = '',
                                            p2s_base1__TransitionDateTime__c = Date.today(),
                                            p2s_base1__Opportunity__c = oppty.Id,
                                            p2s_base1__MostRecent__c = true,
                                            Original_Opportunity_ID__c =oppty.Id );
        cpListToInsert.add (custPath6);

        if (!cpListToInsert.isEmpty())
            insert cpListToInsert;
       OpportunityContactRole optyConRole = new OpportunityContactRole (ContactId = con.Id,
                                                                    OpportunityId = oppty.Id);
        insert optyConRole;
    } // End method
    
    // A method to return custom setting data
    public static List<Sobject> retrieveCustSettingData (String settingName) {
        String queryString = 'SELECT Field_Name__c, Label_Text__c, Line_Break__c, Display_Order__c,' +
                             'Task_Subject__c, Blank_Previous_Value__c  FROM '+ settingName +
                             ' ORDER BY Display_Order__c';
        return Database.query(queryString);
    } // End method

    public static List<DueDateByLOB__c> retrieveDueDate () {
        return DueDateByLOB__c.getall().values();
    } // End method

    // A method to assign task data based off related Contact and Lead obj
    public static Task assignTaskOtherFields (Task pTaskInstance, Sobject pRelObj) {
        if (pTaskInstance == null || pRelObj == null) return null;
        Task taskNew = pTaskInstance;
        taskNew.Form_Fill_Web_Page_Text__c =
                        String.valueOf (pRelObj.get (VariableInitializer.STR_FORMFILLPAGE));
        taskNew.Lead_Activity_Detail_text__c =
                        String.valueOf (pRelObj.get (VariableInitializer.STR_LEADACTVT));
        taskNew.Product_Interest_text__c =
                        String.valueOf (pRelObj.get (VariableInitializer.STR_PRODINT));
        taskNew.Product_Interest_Family_text__c =
                        String.valueOf (pRelObj.get (VariableInitializer.STR_PRODINTFAM));
        taskNew.Line_of_Business__c =
                        String.valueOf (pRelObj.get (VariableInitializer.STR_LOB));
        return taskNew;
    } // End method

    // A method to assign subject and comments dynamically
    public static Sobject fillTaskData (Task taskInstance, Boolean hasAcc,
                                        List<Sobject> custSettingDataList, Sobject relObj) {
        if (custSettingDataList == null || taskInstance == null || relObj == null)
            return null;
        Task taskNew = taskInstance;
        taskNew.Subject = STR_INIT; // Initializing the field
        taskNew.Description = STR_INIT; // Initializing the field
        for (Sobject custSetting : custSettingDataList) {
            String fieldValue, fieldName, prevFieldValue;
            fieldName = String.valueOf (custSetting.get (STR_FIELDNAME));
            System.debug ('fieldName==> '+fieldName);
            System.debug ('hasAcc==> '+hasAcc);
            if (STR_COMPANY.equalsIgnoreCase (fieldName) && hasAcc)
                fieldValue = String.valueOf (relObj.getSobject (STR_ACC).get (STR_NAME));
                else
                fieldValue = String.isNotBlank (fieldName) ? 
                                    String.valueOf (relObj.get (fieldName)):
                                    STR_INIT;
            if ( !Boolean.valueOf (custSetting.get (STR_BLANKPREV)) ||
                 String.isNotBlank (prevFieldValue)) {
                if (Boolean.valueOf (custSetting.get (STR_SUBJECT))) {
                    if (String.isBlank (fieldName) || String.isNotBlank (fieldValue)) {
                        if (String.isNotBlank (String.valueOf (custSetting.get (STR_LABELTXT))))
                            taskNew.Subject += custSetting.get (STR_LABELTXT) + STR_SPACE;
                        if (String.isNotBlank (fieldValue))
                            taskNew.Subject += fieldValue + STR_SPACE;
                    }
                } else {
                    if (String.isBlank (fieldName) || String.isNotBlank (fieldValue)) {
                        if (String.isNotBlank (String.valueOf (custSetting.get (STR_LABELTXT))))
                            taskNew.Description += custSetting.get (STR_LABELTXT) + STR_SPACE;
                        if (String.isNotBlank (fieldValue))
                            taskNew.Description += fieldValue + STR_SPACE;
                        if (Boolean.valueOf (custSetting.get (STR_LINEBRK))) {
                            taskNew.Description += STR_NEWLINE;
                            taskNew.Description += STR_NEWLINE;
                        }
                    }
                } // End else
            }
            prevFieldValue = fieldValue;
        } // End for
        return taskNew;
    } // End method

    // A method that returns query, it accepts two parameters 1) fieldSet fields 2) ObjectName
    public static String getQuery (String fieldSetFields, String objName) {
        String conQueryString = VariableInitializer.STR_SELECT+ STR_SPACE;
        conQueryString += fieldSetFields;
        conQueryString += ID_FIELDNAME+ STR_COMMA+ STR_SPACE+ OWNER_FIELDNAME;
        conQueryString += VariableInitializer.STR_CONTACT.equalsIgnoreCase (objName) || 
                          VariableInitializer.STR_OPPTY.equalsIgnoreCase (objName) ? 
                            STR_COMMA+ STR_SPACE + ACCID_FIELDNAME+ STR_COMMA+ STR_SPACE+ 
                            STR_ACCNAME+ STR_COMMA+ STR_SPACE+ STR_ACCASSIGNISR+ STR_SPACE : '';
        conQueryString += STR_SPACE+ STR_FROM+ STR_SPACE+ objName;
        System.debug ('conQueryString ==> '+conQueryString);
        return conQueryString;
    } // End method

    // A method to return true if the processed object is Contact
    public static Boolean isContactObj (Sobject leadOrConObj) {
        if (leadOrConObj == null) return null;
        return VariableInitializer.STR_CONTACT.equalsIgnoreCase (
                                    leadOrConObj.getSObjectType().getDescribe().getName());
    } // End method

    // A method to return Map of customer path records. Three perameters need to be sent
    // 1) leadOrContactIdSet, 2) ToLifeCycleTransation 3) Boolean if MQI trigger needs tobe checked
    public static Map<String, p2s_base1__CustomerPath__c> getCustpathRecordsMap (
                                     Set<String> objIdSet, String toLifeCycle, Boolean isEnrichTask) {
        Set<String> uniqueIdSet = new Set<String> ();
        Map<String, p2s_base1__CustomerPath__c> objIdCustPathMap = 
                                                        new Map<String, p2s_base1__CustomerPath__c> ();
            for (p2s_base1__CustomerPath__c custPath : [SELECT Id, Execute_MQI_Trigger__c, 
                                                               p2s_base1__Lead__c,
                                                               p2s_base1__Contact__c,
                                                               p2s_base1__ToLifecycleStage__c
                                                        FROM p2s_base1__CustomerPath__c
                                                        WHERE (p2s_base1__Lead__c IN :objIdSet
                                                        OR p2s_base1__Contact__c IN :objIdSet)
                                                        ORDER BY p2s_base1__TransitionDateTime__c
                                                        DESC]) {
                System.debug ('custPath ==> '+custPath);
                if (isEnrichTask)
                   custPath.Execute_MQI_Trigger__c = true;
                String relObjId = String.isNotBlank (custPath.p2s_base1__Contact__c) ? 
                                    custPath.p2s_base1__Contact__c : 
                                    custPath.p2s_base1__Lead__c;
                if (!uniqueIdSet.contains (relObjId) && !objIdCustPathMap.containsKey (relObjId) &&
                      toLifeCycle.equalsIgnoreCase (custPath.p2s_base1__ToLifecycleStage__c))
                    objIdCustPathMap.put (relObjId, custPath);
                    uniqueIdSet.add (relObjId); // Add Ids to pick the latest record in map
          }
          return objIdCustPathMap;
    }

    // A method that returns list of customer path
    public static List<p2s_base1__CustomerPath__c> fetchCPs (Map<String, OpportunityContactRole>
                                                                    pConOpptyIdMap) {
        return [SELECT Id, p2s_base1__Contact__c,
                        p2s_base1__Opportunity__c,
                        p2s_base1__Opportunity__r.Revenue_Type__c,
                        p2s_base1__ToLifecycleStage__c,
                        Original_Opportunity_ID__c,
                        p2s_base1__TransitionDateTime__c
                    FROM p2s_base1__CustomerPath__c
                    WHERE p2s_base1__Contact__c IN :pConOpptyIdMap.keySet()
                    /*AND Id = 'a5560000000Chpt' */
                    ORDER BY p2s_base1__Contact__c, 
                    p2s_base1__TransitionDateTime__c DESC];
    }

    // A method that returns a set of Oppty which have Free Trial revenue type
    private static Set<String> retrieveFreeTrialOppty (Map<String,
                                                        OpportunityContactRole> pConOptyIdMap) {
        Set<String> origionalOpptyIdSet = new Set<String> ();
        for (p2s_base1__CustomerPath__c cPath : fetchCPs (pConOptyIdMap)) {
            if (String.isNotBlank (cPath.Original_Opportunity_ID__c)) {
                origionalOpptyIdSet.add (cPath.Original_Opportunity_ID__c);
            }
        }
        return new Map<String, Opportunity>([SELECT Id FROM Opportunity
                                    WHERE Id IN :origionalOpptyIdSet
                                    AND Revenue_Type__c = : STR_FREETRIAL]).keySet ();
    }
    // A method that updates customer path lookups by UpdateOpptyLookupOnCustPathBatch class
    public static void updateOpptyLookup (Map<String, OpportunityContactRole> pConOptyIdMap) {
        Set<String> cpIdSet = new Set<String> (); // A set to keep a track of recycled custpath
        Set<String> inOpnOpptyCPIds = new Set<String> ();
        Set<String> freeTrialOpptyIdSet = retrieveFreeTrialOppty (pConOptyIdMap);
        List<p2s_base1__CustomerPath__c> custPathToUpdate = 
                                new List<p2s_base1__CustomerPath__c> ();
        for (p2s_base1__CustomerPath__c custPath : fetchCPs (pConOptyIdMap)) {
            if (STAGE_RECYCLED.equals (custPath.p2s_base1__ToLifecycleStage__c)) {
                cpIdSet.add (custPath.p2s_base1__Contact__c);
            }
            OpportunityContactRole opConRole = pConOptyIdMap.get (custPath.p2s_base1__Contact__c);
            if (!cpIdSet.contains(custPath.p2s_base1__Contact__c) && // Incase if the latest
            // transition is InOpenOppty then lookup should be disconnected for that one
                !STAGE_INOPENOPTY.equals (custPath.p2s_base1__ToLifecycleStage__c) &&
                !freeTrialOpptyIdSet.contains (custPath.Original_Opportunity_ID__c)) {
                if (custPath.p2s_base1__TransitionDateTime__c < opConRole.CreatedDate) {
                        custPath.p2s_base1__Opportunity__c =
                        String.isNotBlank (custPath.Original_Opportunity_ID__c) && opConRole.OpportunityId != 
                        custPath.Original_Opportunity_ID__c ? custPath.Original_Opportunity_ID__c:
                        opConRole.OpportunityId;
                    custPathToUpdate.add (custPath);
                }
            } else if (String.isNotBlank (custPath.p2s_base1__Opportunity__c)) {
                custPath.p2s_base1__Opportunity__c = null;
                custPath.Original_Opportunity_ID__c = null;
                custPathToUpdate.add (custPath);
            }
            if (STAGE_INOPENOPTY.equals (custPath.p2s_base1__ToLifecycleStage__c) &&
                cpIdSet.contains(custPath.p2s_base1__Contact__c)) {
                cpIdSet.remove (custPath.p2s_base1__Contact__c);
            }
        } // End for

        if (custPathToUpdate.size () > 0)
            Database.update(custPathToUpdate, false);
    }

    // A method that updates Contact's lifecycle stage whenever they are added on Open Oppty
    public static void updateContactLifeCycleStage (Set<String> pConIdSet) {
        List<Contact> conListToUpdate = new List<Contact> ();
        for (Contact conInstance : [SELECT Id, p2s_base1__LifecycleStage__c
                                        FROM Contact
                                        WHERE Id IN: pConIdSet]) {
            conInstance.p2s_base1__LifecycleStage__c = STAGE_INOPENOPTY;
            conListToUpdate.add (conInstance);
        } // End for
        System.debug ('conListToUpdate ==> '+conListToUpdate);
        System.debug ('conListToUpdate size ==> '+conListToUpdate.size ());
        if (conListToUpdate.size ()> 0)
            Database.update(conListToUpdate, false);
    }// End method

    // A method that returns num of day in the week ex. if 1 = Mon, 4= Thursday
    private static Integer getDay (Date pDateToCal) {
        if (pDateToCal == null) return null;
        Integer diff = Date.newInstance (1900, 1, 7).daysBetween (pDateToCal);
       // System.debug ('dayinGetDay ==> '+Math.mod(diff, 7));
        return (Math.mod(diff, 7));
    } // End method

    // A method that moves the date to next business day if Sutarday or Sunday
    public static Date nextBusinessDay (Date pDueDate) {
        Integer noOfDay = getDay (pDueDate);
        System.debug ('noOfDay ==> '+noOfDay);
        if (noOfDay == 0)
            pDueDate = pDueDate.addDays (1);
        if (noOfDay == 6)
            pDueDate = pDueDate.addDays (2);
        return pDueDate;
    } // End method

   // A method that returns true if the date is Saturday or Sunday
    public static Date skipWeekEnd (Date pDueDate) {
        if (pDueDate == null) return null;
        Integer numOfWeekends =0;
        Integer daysDiff = Date.today().daysBetween (pDueDate);
        System.debug ('daysDiff ==> '+daysDiff);
        System.debug ('pDueDate  ==> '+pDueDate);
        Integer day = getDay (Date.today());
        System.debug ('day ==> '+day);
        if ((day + daysDiff) < 6) { // First week without any weekend
            return pDueDate;
        }
        numOfWeekends = ((day + daysDiff + (7 -day)) / 7);
        System.debug ('numOfWeekends ==> '+numOfWeekends);
        System.debug ('pDueDate1 ==> '+pDueDate);
        pDueDate = pDueDate.addDays (numOfWeekends * 2);
        System.debug ('pDueDate2 ==> '+pDueDate);
        Integer noOfDay = getDay (pDueDate);
        System.debug ('noOfDay ==> '+noOfDay);
        if (noOfDay == 6 || noOfDay == 0) {
            pDueDate = pDueDate.addDays (2);
            System.debug ('Set Date is Weekend==> '+pDueDate);
        }
        System.debug ('Final Date ==> '+pDueDate);
        return pDueDate;
    } // End method
} // End class