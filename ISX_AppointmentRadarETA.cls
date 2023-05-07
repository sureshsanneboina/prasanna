@RestResource(urlMapping='/radar-ETA/*')
global without sharing class ISX_AppointmentRadarETA {
    static final String ERROR_UNHANDLED_EXCEPTION = 'An unhandled Apex exception occurred';
    global class AppointmentRadarETA {
        public string specversion{get;set;}
        public string type{get;set;}
        public string source{get;set;}
        public string id{get;set;}
        public AppointmentData data{get;set;}
    }
    global class AppointmentData{
        public string storeId{get;set;}
        public List<AppointmentIdentities> identities{get;set;}
        public AppointmentETA eta{get;set;}
        public Boolean fromIsx {get;set;}
    }
    global class AppointmentIdentities{
        public string type{get;set;}
        public string value{get;set;}
    }
    global class AppointmentETA{
        public string minutesAwayFromDestination{get;set;}
        public string milesAway{get;set;}
    }
    @HttpPost
    global static void appointmentRadarETA(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json'); 
        try {
            if (req.requestBody == null){
              setReturnResponse(res, 'Please provide an identifying data point.', 400);
                return;
            }
            AppointmentRadarETA objAppointRadarETA = (AppointmentRadarETA)json.deserialize(req.requestBody.toString(),AppointmentRadarETA.Class);
            boolean isSuccess = false;
            
            
            if (!isKMXIdDefined(objAppointRadarETA, res)){
                return;
            }
            List<Account> retrievedAccounts = retrieveAccounts(objAppointRadarETA.data.identities[0].value);
            if ((retrievedAccounts == null) || (retrievedAccounts.isEmpty())){
               
               setReturnResponse(res, 'No accounts associated with the provided data points.', 400); 
                return;
            }
            else if (retrievedAccounts.Size() >= 2){
                setReturnResponse(res, 'Data points are associated with multiple accounts.', 400); 
                return;
            }
            if(objAppointRadarETA.Type == 'com.radar.customer.trip.geofence.entered.v1' || objAppointRadarETA.Type == 'com.radar.customer.trip.destination.arrived.v1' || objAppointRadarETA.Type == 'com.radar.customer.trip.cancelled.v1'){
                updateETA(retrievedAccounts, res, objAppointRadarETA);
                return;
            }
            if(objAppointRadarETA.data == null || objAppointRadarETA.data.eta == null || objAppointRadarETA.data.eta.minutesAwayFromDestination == null){
                setReturnResponse(res, 'No ETA defined in the provided data points.', 400); 
                return;
            }
            
            else{
                updateETA(retrievedAccounts, res, objAppointRadarETA);
                return; 
            }
        }
        catch (Exception ex){
            setReturnResponse(res, ERROR_UNHANDLED_EXCEPTION, 500); 
            return;
        }
    }
    
    
    
    private static boolean isKMXIdDefined(AppointmentRadarETA objAppointRadarETA, RestResponse res){
        
        if(objAppointRadarETA.data == null || objAppointRadarETA.data.identities == null || objAppointRadarETA.data.identities[0].value == null){
             setReturnResponse(res, 'No KMX Id defined in the provided data points.', 400);
                return false;
            }  
        return true;
    }   
    
private static void setReturnResponse(RestResponse res, String body, Integer statusCode){
    res.responseBody = Blob.valueOf(body);
    res.statusCode = statusCode;
}




    private static void updateETA(List<Account> retrievedAccounts,RestResponse res,AppointmentRadarETA objAppointRadarETA){
        List<Opportunity> retrievedOpportunities = retrieveOpportunities(retrievedAccounts);
        if ((retrievedOpportunities == null) || (retrievedOpportunities.isEmpty())){
            res.responseBody = Blob.valueOf('No opportunities associated with the provided data points.');
            res.statusCode = 400;
            return;
        }
        else if (retrievedOpportunities.Size() >= 2){
            res.responseBody = Blob.valueOf('Data points are associated with multiple opportunities.');
            res.statusCode = 400;
            return;
        }
        else{
            List<Event> retrievedEvents = retrieveEvents(retrievedOpportunities);
            if (retrievedEvents == null || retrievedEvents.isEmpty()){
                res.responseBody = Blob.valueOf('No appointments associated with the provided data points.');
                res.statusCode = 400;
                return;
            }
            
            if(objAppointRadarETA.Type != 'com.radar.customer.trip.cancelled.v1'){
                if(objAppointRadarETA.Type == 'com.radar.customer.trip.started.v1'){
                    ISX_AppointmentCheckInApi.CheckInStatusMessage statusMessage;
                    //check in this User
                    String eventId = retrievedEvents[0].Id;
                    List<Event> events = [Select Id, description, type, location from Event where Id = :eventId];
                    if (events.size()>0){
                    Event evt = events[0];
                    Map<String, Object> mapAppointmentElements = new Map<String, Object>{'appointmentId'=>evt.id, 'description' => evt.description, 'appointmentType' => evt.Type, 'store'=>evt.location};
                    //statusMessage = ISX_AppointmentCheckInApi.customerWithAppointment(mapAppointmentElements); 
                    updateEventsAndRelatedObjects(evt.id);  
                    }
                } 
                
                //retrievedEvents[0].Radar_Customer_ETA__c =(objAppointRadarETA.data != null && objAppointRadarETA.data.eta != null &&  objAppointRadarETA.data.eta.minutesAwayFromDestination != null ? objAppointRadarETA.data.eta.minutesAwayFromDestination : '0');
            }
            else{
                //retrievedEvents[0].Radar_Customer_ETA__c = '';
            }
            update retrievedEvents[0];
            res.responseBody = Blob.valueOf('Successfully updated ETA');
            res.statusCode = 200;
            return;
        }
    }
    private static List<Account> retrieveAccounts(string kmxId){
        return [SELECT Id FROM Account WHERE My_KMX_Id__c = :kmxId];
    }
    private static List<Opportunity> retrieveOpportunities(List<Account> retrievedAccounts){
        string accountId = retrievedAccounts[0].id;
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE AccountId = :accountId ]; //AND Status__c = 'Active'
        return opportunities;
    }
    private static List<Event> retrieveEvents(List<Opportunity> retrievedOpportunities){ //todo: Check with Sri/Chris on Event Status filter
        string whatId = retrievedOpportunities[0].id;
        List<Event> events = [SELECT Id, Appointment_Type__c, Lead_Type__c FROM Event WHERE WhatId = :whatId AND (Appointment_Status__c = 'Open' Or Appointment_Status__C = 'Rescheduled' Or Appointment_Status__C = 'Kept') AND StartDateTime = TODAY ORDER BY LastModifiedDate DESC];
        return events;
    }
    
    private static void updateEventsAndRelatedObjects(Id eventId){
        Boolean isRemove = false;
        Boolean isWaiting = true;
        String filter = null;

        
        String storeType;
        Id locationId;
    
        List<Event> lstEvent = [Select Id, WhatId,WhoId,OwnerId,Appointment_Status__c,Description,Appointment_type__c,Lead_Type__c,location,Type,StartDatetime from Event where Id = :eventId];
        if(lstEvent.size() == 0){
            return;
        } 
        
        String requestAppointmenrDesc = lstEvent[0].description;
        String requestAppointmentType = lstEvent[0].Appointment_type__c;
        String store_num = lstEvent[0].location;
        
        if(String.isNotBlank(store_num)){
            List<Location__c> lstLocations = [select Id,Store_Format__c from Location__c Where Store_Number__c = :store_num limit 1];
            if(lstLocations.size() > 0){
                locationId = lstLocations[0].Id;
                storeType = lstLocations[0].Store_Format__c;
            }
        }
    
        List<CRM_WalkInCustomer__c> customerRec = [SELECT Id,Appointment_Id__c FROM CRM_WalkInCustomer__c WHERE Appointment_Id__c = :eventId];
        if(customerRec.size() > 0){
            customerRec[0].Active__c = ((requestAppointmentType == 'ICO Appraisal Appointment' || requestAppointmentType == 'Express Pickup') && storeType == 'Traditional')? false : true;
            customerRec[0].Check_In_Method__c = 'Self';
            //customerRec[0].Time_Out_Reason__c = ((requestAppointmentType == 'ICO Appraisal Appointment' || requestAppointmentType == 'Express Pickup') && storeType == 'Traditional')? 'Assigned' : '';
            customerRec[0].Location__c = locationId;
            if(String.isNotBlank(requestAppointmenrDesc))
                customerRec[0].Description__c = requestAppointmenrDesc.length() > 255 ? requestAppointmenrDesc.left(255) : requestAppointmenrDesc;
            if(String.isNotBlank(requestAppointmentType))
                customerRec[0].Store_Visit_Purpose__c  = requestAppointmentType; 
            update customerRec;
        }else{
            if(lstEvent[0].Appointment_Status__c == 'Open' || lstEvent[0].Appointment_Status__c == 'Rescheduled')
            {
                if(lstEvent[0].WhatId == null && lstEvent[0].WhoId != null){
                    //Lead_Conversion__e event = new Lead_Conversion__e(LeadId__c = lstEvent[0].WhoId, UserId__c = lstEvent[0].OwnerId, EventId__c = eventId);
                    //EventBus.publish(event);
                }
                
                String accountName;
                String accountPhone;
                String situationNotes;
                if(lstEvent[0].WhatId != null){
                    List<Opportunity> lstOpportunity=[Select Account.Name,Account.Phone from Opportunity Where Id = : lstEvent[0].WhatId]; // Situation_Notes__c
                    if(!lstOpportunity.isEmpty()){
                        accountName = lstOpportunity[0].Account.Name;
                        accountPhone = lstOpportunity[0].Account.Phone;
                        //situationNotes = associatedOpportunity.Situation_Notes__c;
                    }
                }else if(lstEvent[0].WhoId != null){
                    List<Lead> lstLead=[Select Name,Phone from Lead Where Id = : lstEvent[0].WhoId]; // Situation_Notes__c
                    if(!lstLead.isEmpty()){
                        accountName = lstLead[0].Name;
                        accountPhone = lstLead[0].Phone;
                    }
                }
                
                String visitPurpose = lstEvent[0].Appointment_type__c;
                if(lstEvent[0].type == 'Web'){
                    visitPurpose = lstEvent[0].Lead_Type__c;
                }
                
                CRM_WalkInCustomer__c chkInCust =new CRM_WalkInCustomer__c();
                chkInCust.Active__c = true;
                chkInCust.Appointment_Id__c = eventId;
                //chkInCust.Assigned_User__c = lstEvent[0].OwnerId;
                chkInCust.Location__c = locationId;
                chkInCust.Name__c = accountName;
                chkInCust.Store_Visit_Purpose__c = visitPurpose;
                chkInCust.Time_In__c = Datetime.now();
                chkInCust.Check_In_Method__c = 'Point';
                //chkInCust.Appointment_Time__c = lstEvent[0].StartDatetime;
                chkInCust.Phone__c = accountPhone;
                chkInCust.Description__c = String.isNotBlank(situationNotes) && situationNotes.length()>255?situationNotes.left(252)+'...':'';
                chkInCust.Is_Walk_In__c = false;
                insert chkInCust;
            }
        } 

    }
}