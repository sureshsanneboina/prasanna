/***********************************************************************************************************************
 * Name     :   ISX_SObjectSelector
 * Author   :   Prassana Kumar
 * Date     :   04/03/23
 * Purpose  :   Sobject SOQL methods.
 **********************************************************************************************************************/
public inherited sharing class ISX_SObjectSelector {
    // Accounts
    /**
     * Returns a list of Accounts by Ids
     * @param accountIdSet Set of Account Id
     * @return List of Accounts
     */
    public static List<Account> getAccountsById(Set<Id> accountIdSet) {
        return [
            SELECT Id, 
                Global_Text_Consent__c, My_KMX_Id__c, Name
            FROM Account
            WHERE Id IN :accountIdSet
        ];
    }

    /**
     * Returns a list of Accounts by KMX Id
     * @param kmxId KMX Id
     * @return List of Accounts
     */
    public static List<Account> getAccountsByKmxId(String kmxId) {
        return [
            SELECT Id, 
                Global_Text_Consent__c, My_KMX_Id__c, Name
            FROM Account
            WHERE My_KMX_Id__c = :kmxId
        ];
    }

    /**
     * Returns a list of Accounts by matching mobile or home phone
     * @param phone Phone Number to filter on
     * @return List of Accounts
     */
    public static List<Account> getAccountsByHomeOrMobilPhone(String phone) {
        return [
            SELECT Id, 
                Global_Text_Consent__c, My_KMX_Id__c, Name
            FROM Account
            WHERE PersonMobilePhone = :phone
                OR PersonHomePhone = :phone
        ];
    }

    // Events
    /**
     * Returns a list of Events by matching Id and Appointment Status
     * @param apptId Event record Id
     * @param lstApptStatus List of appointment statuses to match
     * @return a list of events
     */
    public static List<Event> getEventByIdAppointmentStatus(Id apptId, List<String> lstApptStatus) {
        return [
            SELECT Id,
                AccountId, Appointment_Type__c, Lead_Type__c, Location, Account.My_KMX_Id__c, Account.Name,
                StartDateTime, WhatId, WhoId
            FROM Event
            WHERE Id = :apptId
                AND Appointment_Status__c IN :lstApptStatus
        ];
    }

    /**
     * Returns a list of Events by matching WhoId and Appointment Status
     * @param setWhoId Set of WhoId
     * @param lstApptStatus List of appointment statuses to match
     * @return a list of events
     */
    public static List<Event> getEventsByWhoIdAppointmentStatus(Set<Id> setWhoId, List<String> lstApptStatus) {        
        return [
            SELECT Id, 
                AccountId, Appointment_Type__c, Lead_Type__c, Location, Account.My_KMX_Id__c, Account.Name,
                StartDateTime, WhatId, WhoId
            FROM Event
            WHERE WhoId IN :setWhoId
                AND Appointment_Status__c IN :lstApptStatus
            ORDER BY StartDateTime DESC
        ];
    }

    /**
     * Returns a list of Events by matching WhatId and Appointment Status
     * @param setWhatId Set of WhatId or Opportunity record Id
     * @param lstApptStatus List of appointment statuses to match
     * @return a list of events
     */
    public static List<Event> getEventsByWhatIdAppointmentStatus(Set<Id> setWhatId, List<String> lstApptStatus) {
        return [
            SELECT Id,
                Account.My_KMX_Id__c, Account.Name, AccountId, Appointment_Type__c, Lead_Type__c, Location,
                StartDateTime, WhatId
            FROM Event 
            WHERE WhatId IN :setWhatId 
                AND Appointment_Status__c IN :lstApptStatus
            ORDER BY StartDateTime DESC
        ];
    }

    // Lead
    /**
     * Returns a list of Leads by phone
     * @param cleanedPhoneNumber Cleared phone number
     * @param phoneNumberWithParenthesis Formatted phone number
     * @return List of Leads
     */
    public static List<Lead> getLeadsByPhone(String cleanedPhoneNumber, String phoneNumberWithParenthesis) {
        return [
            SELECT Id 
            FROM Lead 
            WHERE isConverted = false
            AND (
                Phone = :phoneNumberWithParenthesis OR Phone = :cleanedPhoneNumber
            )
        ];
    }

    // Opportunity
    /**
     * Returns a list of Opportunity by matching AccountId and Status
     * @param accountIds Set of Account Id
     * @param lstStatus List of Opportunity statuses to match
     * @return List of Opportunity
     */
    public static List<Opportunity> getOppsByAccountIdAndStatus(Set<Id> accountIds, List<String> lstStatus) {
        return [
            SELECT Id
            FROM Opportunity
            WHERE AccountId IN :accountIds 
                AND Status__c IN :lstStatus
        ];
    }

    // ServiceAppointment
    /**
     * Returns ServiceAppointments by custom filters for Check-in API
     * @param setAppointmentIds Set of Appointment Ids
     * @param setCustomerInteractionIds Set of Customer Interaction Ids
     * @return list of ServiceAppointments
     */
    public static List<ServiceAppointment> getServiceAppointmentsForCheckInApi(
        Set<Id> setAppointmentIds, Set<Id> setCustomerInteractionIds
    ) {
        return [
            SELECT Id,
                AppointmentId__c, Assigned_Store__c, Customer_Interaction__c,
                ParentRecordId, ParentRecordType,
                RecordType.DeveloperName, 
                ServiceTerritory.Name
            FROM ServiceAppointment
            WHERE AppointmentId__c IN :setAppointmentIds
            OR (
                Customer_Interaction__c IN :setCustomerInteractionIds 
                AND RecordType.DeveloperName != :ISX_Cons.REC_TYPE_DEV_NAME_PI_SERVICE_APPOINTMENT
            )
        ];
    }

    // WorkOrderLineItem
    /**
     * Returns Work Order Line Items by Id
     * @param setIds Set of Ids
     * @return list of Work Order Line Items
     */
    public static List<WorkOrderLineItem> getWorkOrderLineItemById(Set<Id> setIds) {
        return [
            SELECT Id,
                WorkOrder.Status, WorkOrder.WO_Vehicle_Stock_Number__c,WorkOrder.Customer_Interaction__c
            FROM WorkOrderLineItem
            WHERE Id = :setIds
            ORDER BY CreatedDate, LastModifiedDate DESC
        ];
    }
}