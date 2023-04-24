@RestResource(urlMapping='/check-in/*')
global without sharing class ISX_AppointmentCheckInApi {

    static final String ERROR_UNHANDLED_EXCEPTION = 'An unhandled Apex exception occurred';
    
    global class ResponseMsg {
        public string workOrderStatus {get; set;}
        public string stockNumber {get; set;}
        public List<AppointmentForCheckIn> eventInfo {get; set;}
    }
    
    global class AppointmentForCheckIn {
        public string appointmentId {get; set;}
        public string appointmentType {get; set;}
        public string workOrderStatus {get; set;}
        public string stockNumber {get; set;}
        public string storeId {get; set;}
        public Datetime appointmentDatetime {get;set;}
        public string crmId {get;set;}
        public string ciid {get;set;}
        public string ciamid {get;set;}
        public string customerName {get;set;}
    }

    /*
    /services/apexrest/check-in/?phone-number=2403393813
    {
    "appointmentId" : "00U2h0000036VkwEAE",
    "appointmentType" : "0051C000009hjQRQAY"
    }      
    */
    @HttpGet
    global static void getAppointmentForCheckIn(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<Account> retrievedAccounts;
        List<Event> retrievedEvents;
        AppointmentForCheckIn retrievedReturndata;
        ResponseMsg responseWrapper;
        
        Map<string, string> retrievedParameters = retrieveInputParameters(req);
        system.debug(retrievedParameters);
        if ((retrievedParameters == null) || (retrievedParameters.isEmpty())){
            res.responseBody = Blob.valueOf('Please provide an identifying data point.');
            res.statusCode = 400;
            return;
        }
        
        try {
            //getting appointment details using appointment id (18 or 15 digit)
            if (retrievedParameters.containsKey('appt-id')) {
                retrievedEvents = retrieveEvents(retrievedParameters.get('appt-id'));
                if (ISX_FilterUtil.isNullOrEmpty(retrievedEvents)) {
                    res.responseBody = Blob.valueOf('No appointments associated with the provided data points.');
                    res.statusCode = 400;
                    return;
                }
                retrievedReturndata = prepareAppointmentResponse(retrievedEvents[0]);
                responseWrapper =new ResponseMsg();
                responseWrapper.workOrderStatus = 'test';
                responseWrapper.stockNumber= '1234';
                responseWrapper.eventInfo= new List<AppointmentForCheckIn>{retrievedReturndata};
                res.responseBody = Blob.valueOf(JSON.serialize(retrievedReturndata));
                res.statusCode = 200;
                return;
            }
            //getting appointment details using customers phone number
            if (retrievedParameters.containsKey('phone-number')) {
                if (!checkPhoneNumberRegex(retrievedParameters.get('phone-number'))) {
                    res.responseBody = Blob.valueOf('Please provide a valid phone number.');
                    res.statusCode = 400;
                    return;
                }
                retrievedAccounts = retrieveAccountsViaPhone(retrievedParameters.get('phone-number'));
            }
            else {
                retrievedAccounts = retrieveAccountsViaOtherParams(retrievedParameters);
            }


            if (!validatedAccounts(retrievedAccounts, res)) {
                return;
            }
            
            List<Opportunity> retrievedOpportunities = retrieveOpportunities(retrievedAccounts);

            if (!processData(retrievedOpportunities, retrievedParameters, retrievedEvents, retrievedReturndata, res)) {
                return;
            }
        } catch (Exception ex){
            res.responseBody = Blob.valueOf(ERROR_UNHANDLED_EXCEPTION);
            res.statusCode = 500;
            return;
        }
    }

    /**
     * Further processes data
     * @param retrievedOpportunities Queried Opportunities
     * @param retrievedParameters Params from request
     * @param retrievedEvents  Queried Events
     * @param retrievedReturndata Response wrapper
     * @param res Http response
     * @return True if data is valid
     */
    private static boolean processData(
        List<Opportunity> retrievedOpportunities,
        Map<string, string> retrievedParameters,
        List<Event> retrievedEvents,
        AppointmentForCheckIn retrievedReturndata,
        RestResponse res
    ) {
    if (ISX_FilterUtil.isNullOrEmpty(retrievedOpportunities)) {
        List<Lead> retrievedLeads = retrieveLeadsViaPhone(retrievedParameters.get('phone-number'));
        if (ISX_FilterUtil.isNullOrEmpty(retrievedLeads)) {
            res.responseBody = Blob.valueOf('No opportunities/leads with the provided data points.');
            res.statusCode = 204;
            return false;
        }
        else {
            retrievedEvents = retrieveNonConLeadEvents(retrievedLeads);
            if (ISX_FilterUtil.isNullOrEmpty(retrievedEvents)) {
                res.responseBody = Blob.valueOf('No appointments associated with the provided data points.');
                res.statusCode = 204;
                return false;
            }

            retrievedReturndata = prepareAppointmentResponse(retrievedEvents[0]);  
            
            ResponseMsg responseWrapper =new ResponseMsg();
            responseWrapper.workOrderStatus = 'test';
            responseWrapper.stockNumber= '1234';
            responseWrapper.eventInfo= new List<AppointmentForCheckIn>{retrievedReturndata};
                   
            res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
            res.statusCode = 200;
            return false;
        }
    }
    else if (retrievedOpportunities.Size() >= 2) {
        res.responseBody = Blob.valueOf('Data points are associated with multiple opportunities.');
        res.statusCode = 204;
        return false;
    }
    
    retrievedEvents = retrieveEvents(retrievedOpportunities);
    if (retrievedEvents == null || retrievedEvents.isEmpty()){
        res.responseBody = Blob.valueOf('No appointments associated with the provided data points.');
        res.statusCode = 204;
        return false;
    }
    
    retrievedReturndata = prepareAppointmentResponse(retrievedEvents[0]); 
    
    ResponseMsg responseWrapper =new ResponseMsg();
    responseWrapper.workOrderStatus = 'test';
    responseWrapper.stockNumber= '1234';
    responseWrapper.eventInfo= new List<AppointmentForCheckIn>{retrievedReturndata};
           
    res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
    res.statusCode = 200;
    return false;
    
    }

    /**
     * Validates retrieved Accounts
     * @param retrievedAccounts Queried Accounts
     * @param res Response
     * @return True if valid
     */
    private static boolean validatedAccounts(List<Account> retrievedAccounts,  RestResponse res){

        if (ISX_FilterUtil.isNullOrEmpty(retrievedAccounts)) {
            res.responseBody = Blob.valueOf('No Accounts associated with the provided data points.');
            res.statusCode = 204;
            return false;
        }
        else if (retrievedAccounts.Size() >= 2) {
            res.responseBody = Blob.valueOf('Data points are associated with multiple accounts.');
            res.statusCode = 204;
            return false;
        }
        else if (retrievedAccounts[0].Global_Text_Consent__c == 'Opt Out'){
            res.responseBody = Blob.valueOf('Opted out');
            res.statusCode = 400;
            return false;
        }

        return true;
    }


    private static Map<string, string> retrieveInputParameters(RestRequest req){
        List<string> validParameters = new List<string> {'crm-id','phone-number', 'kmx-id', 'appt-id'};
        Map<string, string> collectedParameters = new Map<string, string>();
        for (string parameter : validParameters){
            string retrievedParameter = req.params.get(parameter);
            if(!String.isEmpty(retrievedParameter)){
                collectedParameters.put(parameter, retrievedParameter);
            }
        }
        return collectedParameters;
    }
    
    private static boolean checkPhoneNumberRegex(string phoneNumber){
        Pattern p = Pattern.compile('\\(?\\d{3}\\)?-? *\\d{3} *-? *-?\\d{4}');
        Matcher pm = p.matcher(phoneNumber);
        return pm.matches();
    }

    private static List<Lead> retrieveLeadsViaPhone( string phoneNumber){
        string cleanedPhoneNumber = phoneNumber.replaceAll('[^0-9]','');
        string phoneNumberWithParenthesis = '(' + cleanedPhoneNumber.substring(0,3) + ') ' + cleanedPhoneNumber.substring(3, 6) + '-' + cleanedPhoneNumber.substring(6);
        return [SELECT Id from Lead WHERE (Phone=:phoneNumberWithParenthesis or Phone=:cleanedPhoneNumber) and isConverted=false];
    }

    /**
     * Retrieves Accounts by phone number
     * @param phoneNumber Phone Number to match
     * @return List of Accounts
     */
    private static List<Account> retrieveAccountsViaPhone( string phoneNumber){
        string cleanedPhoneNumber = phoneNumber.replaceAll('[^0-9]','');
        string phoneNumberWithParenthesis = '(' + cleanedPhoneNumber.substring(0,3) + ') ' + cleanedPhoneNumber.substring(3, 6) + '-' + cleanedPhoneNumber.substring(6);
        
        List<Account> accounts = [SELECT Id, Name, Global_Text_Consent__c, My_KMX_Id__c FROM Account WHERE Phone = :cleanedPhoneNumber];
        if (!ISX_FilterUtil.isNullOrEmpty(accounts)) {
            return accounts;
        }
        
        accounts = [SELECT Id, Name, Global_Text_Consent__c, My_KMX_Id__c FROM Account WHERE Phone = :phoneNumberWithParenthesis];
        if (!ISX_FilterUtil.isNullOrEmpty(accounts)) {
            return accounts;
        }
        
        accounts = [SELECT Id, Name, Global_Text_Consent__c, My_KMX_Id__c FROM Account WHERE Phone = :cleanedPhoneNumber];
        if (!ISX_FilterUtil.isNullOrEmpty(accounts)) {
            return accounts;
        }
        
        accounts = [SELECT Id, Name, Global_Text_Consent__c, My_KMX_Id__c FROM Account WHERE Phone = :phoneNumberWithParenthesis];
        if (!ISX_FilterUtil.isNullOrEmpty(accounts)) {
            return accounts;
        }
        return null;
    }
    
    /**
     * Retrieves Accounts by matching other params
     * @param retrievedParameters Params map from request
     * @return list of Accounts
     */
    private static List<Account> retrieveAccountsViaOtherParams( Map<string, string> retrievedParameters) {
        boolean crmId = false;
        boolean kmxId = false;
        String rpCopy; 

        for (string key : retrievedParameters.keySet()){
            string retrievedParameter = retrievedParameters.get(key);
            switch on key {
                when  'crm-id' {
                    crmId = true;
                    rpCopy = retrievedParameter;
                }
                when 'kmx-id' {
                    kmxId = true;
                    rpCopy = retrievedParameter;
                }              
            }
        }

        if (crmId) {
            List<Account> accounts = 
                [SELECT Id, Name, Global_Text_Consent__c, My_KMX_Id__c FROM Account WHERE Id = :rpCopy];
            if (!ISX_FilterUtil.isNullOrEmpty(accounts)) {
                return accounts;
            }
        } else if (kmxId) {
            List<Account> accounts =
                [SELECT Id, Name, Global_Text_Consent__c, My_KMX_Id__c FROM Account WHERE My_KMX_Id__c = :rpCopy];
            if (!ISX_FilterUtil.isNullOrEmpty(accounts)) {
                return accounts;
            }
        }
        
       return null;
    }

    /**
     * Retrieves Opportunities for Accounts
     * @param retrievedAccounts Queried Accounts
     * @return List of Opportunities
     */
    private static List<Opportunity> retrieveOpportunities(List<Account> retrievedAccounts){
        string accountId = retrievedAccounts[0].id;
        List<Opportunity> opportunities = 
            ISX_SObjectSelector.getOppsByAccountStatus(accountId, new List<String>{ ISX_Cons.STATUS_ACTIVE });
        return opportunities;
    }

    /**
     * Retrieves Events by WhatId/Opportunity Id
     * @param retrievedOpportunities Queried Opportunities
     * @return list of Events
     */
    private static List<Event> retrieveEvents(List<Opportunity> retrievedOpportunities) {
        string whatId = retrievedOpportunities[0].id;
        List<String> lstApptStatus = new List<String> { ISX_Cons.APPT_STATUS_OPEN, ISX_Cons.APPT_STATUS_RESCHEDULED };
        return ISX_SObjectSelector.getEventByIdAppointmentStatus(whatId, lstApptStatus);
    }

    private static List<Event> retrieveNonConLeadEvents(List<Lead> retrievedLeads){
        string whatId = retrievedLeads[0].id;
        List<Event> events = [SELECT Id, Appointment_Type__c, Lead_Type__c, StartDateTime, Location FROM Event WHERE WhoId = :whatId AND (Appointment_Status__c = 'Open' Or Appointment_Status__C = 'Rescheduled') AND StartDateTime = TODAY ORDER BY LastModifiedDate DESC];
        return events;
    }

    /**
     * Retrieves Events by appointment id
     * @param apptId Appointment record Id
     * @return List of events
     */
    private static List<Event> retrieveEvents(Id apptId) {
        List<String> lstApptStatus = new List<String> { ISX_Cons.APPT_STATUS_OPEN, ISX_Cons.APPT_STATUS_RESCHEDULED };
        return ISX_SObjectSelector.getEventByIdAppointmentStatus(apptId, lstApptStatus);
    }
    
    /**
     * Prepares appointment response
     * @param retrievedEvent Event record
     * @return AppointmentForCheckIn wrapper
     */
    private static AppointmentForCheckIn prepareAppointmentResponse(Event retrievedEvent){
        string returnAppointmentType = '';
        String appointmentType = '';

        if(string.isNotBlank(retrievedEvent.Appointment_Type__c)){
            appointmentType = retrievedEvent.Appointment_Type__c;
        }
        else if (string.isNotBlank(retrievedEvent.Lead_Type__c)){
            appointmentType = retrievedEvent.Lead_Type__c;
        }

        if (string.isNotBlank(appointmentType)){
            returnAppointmentType = constructAppointmentTypesString(appointmentType);
        }

        AppointmentForCheckIn returnData = new AppointmentForCheckIn();   
        returnData.appointmentId = retrievedEvent.id;
        returnData.appointmentType = returnAppointmentType;
        returnData.appointmentDatetime = retrievedEvent.StartDateTime;
        returnData.storeId = retrievedEvent.Location;
        returnData.crmId = retrievedEvent.AccountId;
        returnData.customerName = retrievedEvent.Account.Name;
        returnData.ciamid = retrievedEvent.Account.My_KMX_Id__c;
        returnData.ciid = retrievedEvent.WhatId;

        return retieveStockNumberAndWOStatus(retrievedEvent, returnData);
    }

    private static String constructAppointmentTypesString(String appointmentType){
        string returnAppointmentType = '';
        if (appointmentType.containsIgnoreCase('Browse') || appointmentType.containsIgnoreCase('Test Drive') || appointmentType.containsIgnoreCase('TestDrive') 
        || appointmentType.containsIgnoreCase('Hold') || appointmentType.containsIgnoreCase('Appointment Reservation') || appointmentType.containsIgnoreCase('Buy')){
            returnAppointmentType = shouldAddSemiColon(returnAppointmentType) + 'Browse';
        }

        if (appointmentType.containsIgnoreCase('Finance') || appointmentType.containsIgnoreCase('Financing') || appointmentType.containsIgnoreCase('Financing Info')){
            returnAppointmentType = shouldAddSemiColon(returnAppointmentType) + 'Financing';
        }

        if (appointmentType.containsIgnoreCase('Appraisal') && !appointmentType.containsIgnoreCase('ICO Appraisal Appointment')){
            returnAppointmentType = shouldAddSemiColon(returnAppointmentType) + 'Appraisal';
        }

        if (appointmentType.containsIgnoreCase('ICO Appraisal Appointment')){
            returnAppointmentType = shouldAddSemiColon(returnAppointmentType) + 'ICO Appraisal Appointment';
        }

        if (appointmentType.containsIgnoreCase('Express Pick Up')){
            returnAppointmentType = shouldAddSemiColon(returnAppointmentType) + 'Express Pickup';
        }
        return returnAppointmentType;
    }
    
    private static AppointmentForCheckIn retieveStockNumberAndWOStatus(Event retrievedEvent, AppointmentForCheckIn returnData){
        String workOrderStatus = '';
        String stockNumber = '';
        //retrieve workorderstatus and stocknumber
        /*List<serviceAppointment> lstSA;
        lstSA = [select Id, ParentRecordId, RecordType.DeveloperName, ParentRecordType, ServiceTerritory.Name, Assigned_Store__c from ServiceAppointment where AppointmentId__c =: retrievedEvent.id and AppointmentId__c != null];
        if(lstSA.size() == 0){
            //get ci using appt id
            List<Event> lstEvnt = [select Id, WhatId from event where id=:retrievedEvent.id];
            String ciId;
            if(lstEvnt.size() > 0){
                ciId = lstEvnt[0].WhatId;
            }
            //get sa using ci id
            if(String.isNotBlank(ciId)){
                lstSA = [select Id, ParentRecordId, RecordType.DeveloperName, ParentRecordType, ServiceTerritory.Name, Assigned_Store__c from ServiceAppointment where Customer_Interaction__c=:ciId and RecordType.DeveloperName != 'PI_Service_Appointment'];
            } 
        }
        if(lstSA.size() > 0 && lstSA[0].ParentRecordType == 'WorkOrderLineItem' && String.isNotBlank(lstSA[0].ParentRecordId) && lstSA[0].RecordType.DeveloperName == 'Field_Service'){
            workorderlineitem lineitem = [select WorkOrder.Status, WorkOrder.WO_Vehicle_Stock_Number__c from workorderlineitem where Id = :lstSA[0].ParentRecordId];
            workOrderStatus = (lineitem.WorkOrder.Status != null) ? lineitem.WorkOrder.Status : '';
            stockNumber = (lineitem.WorkOrder.WO_Vehicle_Stock_Number__c != null) ? lineitem.WorkOrder.WO_Vehicle_Stock_Number__c : '';
        }
        returnData.workOrderStatus = workOrderStatus; 
        returnData.stockNumber = stockNumber; */
        return returnData;
    }

    private static string shouldAddSemiColon(string providedString){
        if (!string.isBlank(providedString)){
            return providedString + ';';
        }
        return providedString;
    }
    
  /*
    Input Payload
    CUSTOMER WITHOUT APPOINTMENT
    {
        "item": {
            "customer": {
                "firstName": "Test5",
                "lastName": "Cincy",
                "email":"test5cincy@test.com",
                "phone":"5021234546"
            },
            "appointment": {
                "appointmentId": "",
                "appointmentType": "Browse;Appraisal",
                "description": "Trading in based on offer",
                "store": "7102"
            }
        }
    } 

    CUSTOMER WITH APPOINTMENT
    {
        "item": {
            "appointment": {
                "appointmentId": "018digitsalesforce",
                "appointmentType": "Browse;Appraisal",
                "description": "Trading in based on offer",
                "store": "7101"
            }
        }
    }
    */

    public enum CheckInStatusMessage { ITEM_NODE_MISSING_FROM_INPUT_PAYLOAD, 
                               APPOINTMENT_NODE_MISSING_FROM_INPUT_PAYLOAD,
                               CUSTOMER_NODE_MISSING_FROM_INPUT_PAYLOAD,
                               APPOINTMENT_ID_MISSING_FROM_INPUT_PAYLOAD,
                               INVALID_APPOINTMENT_ID,
                               CHECKIN_SUCCESSFUL,
                               UNHANDLED_APEX_EXCEPTION_OCCURRED,
                               CUST_DETAILS_FIRSTNAME_LASTNAME_MISSING
                            }

  @HttpPost
  global static void checkInAppointment(){
    CheckInStatusMessage statusMessage;
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    Map<CheckInStatusMessage, String> mapStatusMessages = new Map<CheckInStatusMessage, String>{ 
        CheckInStatusMessage.ITEM_NODE_MISSING_FROM_INPUT_PAYLOAD => 'item node is missing in the payload',
        CheckInStatusMessage.APPOINTMENT_NODE_MISSING_FROM_INPUT_PAYLOAD => 'appointment node is missing in the payload',
        CheckInStatusMessage.CUSTOMER_NODE_MISSING_FROM_INPUT_PAYLOAD => 'customer node is missing in the payload',
        CheckInStatusMessage.APPOINTMENT_ID_MISSING_FROM_INPUT_PAYLOAD => 'appointmentId is blank in the payload',
        CheckInStatusMessage.INVALID_APPOINTMENT_ID => 'Invalid appointmentId',
        CheckInStatusMessage.CHECKIN_SUCCESSFUL => 'CheckIn is Successful',
        CheckInStatusMessage.UNHANDLED_APEX_EXCEPTION_OCCURRED => 'An unhandled Apex exception occurred',
        CheckInStatusMessage.CUST_DETAILS_FIRSTNAME_LASTNAME_MISSING => 'First Name and Last Name are required'};

    Map<String, Object> mapMainElements = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
    Map<String, Object> mapItemElements = (Map<String, Object>) mapMainElements.get('item');
    if(mapItemElements == null){
        res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.ITEM_NODE_MISSING_FROM_INPUT_PAYLOAD));
        res.statusCode = 400;
        return;
    }

    Map<String, Object> mapCustomerElements = (Map<String, Object>)mapItemElements.get('customer');
    Map<String, Object> mapAppointmentElements = (Map<String, Object>)mapItemElements.get('appointment');
    if(mapAppointmentElements == null){
        res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.APPOINTMENT_NODE_MISSING_FROM_INPUT_PAYLOAD));
        res.statusCode = 400;
        return;
    }
    
    if(String.isNotBlank((String)mapAppointmentElements.get('appointmentId'))){
        system.debug('###### customer with appointment: ' + mapAppointmentElements.get('appointmentId'));
        statusMessage = customerWithAppointment(mapAppointmentElements); 
    }
    else {
        system.debug('###### Customer without appointment: ' + mapAppointmentElements.get('appointmentId'));
        statusMessage = customerWithOutAppointment(mapCustomerElements, mapAppointmentElements);
    }
    
    switch on statusMessage {
        when CUSTOMER_NODE_MISSING_FROM_INPUT_PAYLOAD {
            res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.CUSTOMER_NODE_MISSING_FROM_INPUT_PAYLOAD));
            res.statusCode = 400;
            return;
        }
        /*when APPOINTMENT_ID_MISSING_FROM_INPUT_PAYLOAD {
            res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.APPOINTMENT_ID_MISSING_FROM_INPUT_PAYLOAD));
            res.statusCode = 400;
            return;
        }*/
        when INVALID_APPOINTMENT_ID {
            res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.INVALID_APPOINTMENT_ID));
            res.statusCode = 400;
            return;
        }
        when CUST_DETAILS_FIRSTNAME_LASTNAME_MISSING {
            res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.CUST_DETAILS_FIRSTNAME_LASTNAME_MISSING));
            res.statusCode = 400;
            return;
        }
        when CHECKIN_SUCCESSFUL {
            res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.CHECKIN_SUCCESSFUL));
            res.statusCode = 200;
            return;
        }
        when else {
            res.responseBody = Blob.valueOf(mapStatusMessages.get(CheckInStatusMessage.UNHANDLED_APEX_EXCEPTION_OCCURRED));
            res.statusCode = 500;
            return;
        }
    }
    
  }

  //logic for 'Customer without appointment'
  //following method creates a crm_walkin_customer__c record
  public static CheckInStatusMessage customerWithOutAppointment(Map<String, Object> mapCustomerElements, Map<String, Object> mapAppointmentElements){

    if(mapCustomerElements == null){
        return CheckInStatusMessage.CUSTOMER_NODE_MISSING_FROM_INPUT_PAYLOAD;
    }

    String firstname = (String)mapCustomerElements.get('firstName');
    String lastName = (String)mapCustomerElements.get('lastName');
    String phone = (String)mapCustomerElements.get('phone');
    String appointmentType = (String) mapAppointmentElements.get('appointmentType');
    String appointmentDesc = (String)mapAppointmentElements.get('description');
    String store_num = (String)mapAppointmentElements.get('store');
    
    if(String.isBlank(firstName) || String.isBlank(lastName)){
        return CheckInStatusMessage.CUST_DETAILS_FIRSTNAME_LASTNAME_MISSING;
    }

    Id locationId;
    String storeType;
    if(String.isNotBlank(store_num)){
        List<Location__c> lstLocations = [select Id,Store_Format__c from Location__c Where Store_Number__c = :store_num limit 1];
        if(lstLocations.size() > 0){
            locationId = lstLocations[0].Id;
            storeType = lstLocations[0].Store_Format__c;
        }
    }
    
    /*
    CRM_WalkInCustomer__c walkinObj = new CRM_WalkInCustomer__c(
            Active__c = (appointmentType == 'ICO Appraisal Appointment' && storeType == 'Traditional')? false : true,
            Check_In_Method__c = 'Self',
            Description__c = (String.isNotBlank(appointmentDesc) && appointmentDesc.length() > 255)? appointmentDesc.left(255) : appointmentDesc,
            Location__c = locationId,
            Name__c = ((firstname + ' ' + lastName).length() > 50)? firstname.left(48) + ' ' +  lastName.left(1) : firstname + ' ' + lastName,
            Phone__c = phone,
            Store_Visit_Purpose__c = appointmentType, 
            Time_In__c = Datetime.now(),
            Is_Walk_In__c = true,
            Email__c = (String)mapCustomerElements.get('email') 
        );
    insert walkinObj;*/

    return CheckInStatusMessage.CHECKIN_SUCCESSFUL;
    
  }

  //Logic for 'Customers with appointment'
  //Following method is used to checkin an existing appointment
  public static CheckInStatusMessage customerWithAppointment(Map<String, Object> mapAppointmentElements){
    Boolean isRemove = false;
    Boolean isWaiting = true;
    String filter = null;
    String requestAppointmentId = (String) mapAppointmentElements.get('appointmentId');
    String requestAppointmenrDesc = (String)mapAppointmentElements.get('description');
    String requestAppointmentType = (String) mapAppointmentElements.get('appointmentType');
    String store_num = (String)mapAppointmentElements.get('store');
    String storeType;
    Id locationId;

    if(String.isNotBlank(store_num)){
        List<Location__c> lstLocations = [select Id,Store_Format__c from Location__c Where Store_Number__c = :store_num limit 1];
        if(lstLocations.size() > 0){
            locationId = lstLocations[0].Id;
            storeType = lstLocations[0].Store_Format__c;
        }
    }

    List<Event> lstEvent = [Select Id, WhatId,OwnerId,Description,Appointment_type__c,Lead_Type__c from Event where Id = :requestAppointmentId];
    if(lstEvent.size() == 0){
        return CheckInStatusMessage.INVALID_APPOINTMENT_ID;
    } 
    
    //CRM_Point_CheckIn_Appointments.updateAppt(lstEvent[0].OwnerId, requestAppointmentId, isRemove, isWaiting, filter);
    
    //Update the CRM_WalkInCustomer__c record
    /*List<CRM_WalkInCustomer__c> customerRec = [SELECT Id,Appointment_Id__c FROM CRM_WalkInCustomer__c WHERE Appointment_Id__c = :requestAppointmentId];
    if(customerRec.size() > 0){
        customerRec[0].Active__c = ((requestAppointmentType == 'ICO Appraisal Appointment' || requestAppointmentType == 'Express Pickup') && storeType == 'Traditional')? false : true;
        customerRec[0].Check_In_Method__c = 'Self';
        customerRec[0].Time_Out_Reason__c = ((requestAppointmentType == 'ICO Appraisal Appointment' || requestAppointmentType == 'Express Pickup') && storeType == 'Traditional')? 'Assigned' : '';
        customerRec[0].Location__c = locationId;
        if(String.isNotBlank(requestAppointmenrDesc))
            customerRec[0].Description__c = requestAppointmenrDesc.length() > 255 ? requestAppointmenrDesc.left(255) : requestAppointmenrDesc;
        if(String.isNotBlank(requestAppointmentType))
            customerRec[0].Store_Visit_Purpose__c  = requestAppointmentType; 
        update customerRec;
    } */

    //Appointment's related Opportunity fields for Shopping, Selling and Financing status are updated to reflect the request
    updateOppWithRequest(lstEvent, requestAppointmentType);
    return CheckInStatusMessage.CHECKIN_SUCCESSFUL;
  }
    
    
    private static void updateOppWithRequest(List<Event> lstEvent, String requestAppointmentType){
        
        List<Opportunity> opportunityRec = [SELECT Id,CEC_Selling_Status__c , CEC_Shopping_Status__c, CEC_Financing_Status__c FROM Opportunity WHERE Id = :lstEvent[0].WhatId LIMIT 1]; //
    if(opportunityRec.size() > 0 && String.isNotBlank(requestAppointmentType)){  
        // Shopping Status Updates when Appointment Type is 'Browse'  
        oppShoppingStatusUpdates1(requestAppointmentType, opportunityRec);    
        oppShoppingStatusUpdates2(requestAppointmentType, opportunityRec);            
        update opportunityRec[0];
    }  
        
        
    }
     private static void oppShoppingStatusUpdates2(String requestAppointmentType, List<Opportunity> opportunityRec){

         If(requestAppointmentType.containsIgnoreCase('Browse') && opportunityRec[0].CEC_Shopping_Status__c == null){
            opportunityRec[0].CEC_Shopping_Status__c = 'Needs help shopping';   
        }           

        // Financing Status Updates when Appointment Type is 'Financing'   
        If(requestAppointmentType.containsIgnoreCase('Financing') && (opportunityRec[0].CEC_Financing_Status__c == null || opportunityRec[0].CEC_Financing_Status__c == 'Financing Elsewhere' || opportunityRec[0].CEC_Financing_Status__c == 'Paying Cash')){ 
            opportunityRec[0].CEC_Financing_Status__c = 'Finance through CarMax';    
        }     

        // Selling Status Updates when Appointment Type is 'Appraisal'  
        If(requestAppointmentType.containsIgnoreCase('Appraisal')){ 
            If(opportunityRec[0].CEC_Selling_Status__c  == null || (opportunityRec[0].CEC_Selling_Status__c == 'Appraisal Only' && requestAppointmentType.containsIgnoreCase('Browse')) || opportunityRec[0].CEC_Selling_Status__c == 'No Trade or Declined Appraisal'){
                opportunityRec[0].CEC_Selling_Status__c= 'Trade-In';
            }  
        }

     }
    private static void oppShoppingStatusUpdates1(String requestAppointmentType, List<Opportunity> opportunityRec){
        System.debug('### requestAppointmentType.containsIgnoreCase(ICO Appraisal Appointment): '+requestAppointmentType.containsIgnoreCase('ICO Appraisal Appointment'));
        System.debug('### requestAppointmentType.containsIgnoreCase(Browse)'+requestAppointmentType.containsIgnoreCase('Browse'));
        System.debug('### opportunityRec[0].CEC_Selling_Status__c: '+opportunityRec[0].CEC_Selling_Status__c);
        // Selling Status Updates when Appointment Type is 'ICO Appraisal'  Lead type 'ICO Appraisal Appointment'
        If(requestAppointmentType.containsIgnoreCase('ICO Appraisal Appointment') && requestAppointmentType.containsIgnoreCase('Browse') && (opportunityRec[0].CEC_Selling_Status__c  == null || opportunityRec[0].CEC_Selling_Status__c == 'Appraisal Only' || opportunityRec[0].CEC_Selling_Status__c == 'No Trade or Declined Appraisal')){ 
            opportunityRec[0].CEC_Selling_Status__c= 'Trade-In';
        }
        If(requestAppointmentType.containsIgnoreCase('ICO Appraisal Appointment') && !requestAppointmentType.containsIgnoreCase('Browse') && opportunityRec[0].CEC_Selling_Status__c == 'No Trade or Declined Appraisal'){ 
            opportunityRec[0].CEC_Selling_Status__c = 'Appraisal Only';
        }

    }
}