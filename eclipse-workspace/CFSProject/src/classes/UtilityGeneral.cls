/**
 * Description: This is a utility class that contains static methods to use as helper functions
 * 
 **/
public with sharing class UtilityGeneral {

    // A method to build query 
    public static String buildQuery (List<Schema.FieldSetMember> fsMember, String objName) {
        String query = ' SELECT ';
        for (Schema.FieldSetMember f : fsMember) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id FROM ' + objName;
        return query;
    } // End method

    // A method to wrap ID in single quote
    public static String wrapInSingleQuotes (String objId) {
        return '\'' + objId + '\'';
    }// End method
}