@isTest
public class ISX_AppointmentRadarETATest {
     @testSetup
    public static void TestData(){
        test.startTest();
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive=true LIMIT 1];
        User salesConsultant1;
        String storeNum = '8901';

        /*KMX_Apex_Custom_Settings__c testCustomSettings = new KMX_Apex_Custom_Settings__c();
        testCustomSettings.Name = 'Settings';
        testCustomSettings.OriginationForCallout__c = 'CRM';
        testCustomSettings.SendOppTeamMemberActive__c = false; 
        upsert testCustomSettings;*/

        System.runAs(sysAdmin) {
            Location__c testLoc = new Location__c();
            testLoc.Store_Name__c = 'TestMax9999';
            testLoc.Store_Number__c = storeNum;
            testLoc.CRM_Active__c = true;
            upsert testLoc;

            Profile scProfile = [SELECT Id FROM Profile Where Profile.Name = 'System Administrator'  limit 1];
            UserRole scRole = [SELECT Id FROM UserRole LIMIT 1];
            User userI = createTestUser('1sc',scRole.Id,scProfile.Id,storeNum,'Ups List');
            insert userI;

            //RecordType pAccRecordType = [SELECT Id, sObjectType, Name FROM RecordType WHERE Name='Person Account' AND sObjectType = 'Account' LIMIT 1];
            Account testAccount = new Account();
            //testAccount.RecordTypeId = pAccRecordType.Id;
            //testAccount.FirstName = 'test';
            testAccount.Name= 'account';
            testAccount.Phone = '8045551212';        
            //testAccount.PersonEmail ='test@example.com';
            //testAccount.URI__c = 'name';
            insert testAccount;

            opportunity opp = new opportunity();
            opp.Name = 'point test opp';
            opp.stageName = 'Finance';
            opp.OwnerId = userI.id;
            opp.CloseDate = Date.TODAY().addDays(4);
            //opp.Home_Delivery_Flag__c = FALSE;
            opp.LeadSource='Web';
            //opp.Established_Dialog__c = false;
            opp.accountId = testAccount.id;
            insert opp;

            Event appt = new Event();
            appt.StartDatetime = datetime.now();
            appt.Location = testLoc.Store_Number__c;
            //appt.Assigned_Store__c = testLoc.Id;
            appt.Appointment_Status__c='Open';
            appt.Appointment_type__c='Browse;hold;Finance;Appraisal';
            appt.WhatId = opp.id;
            appt.DurationInMinutes = 60;
            insert appt;
        }
        test.stopTest();
    }
    private static User createTestUser(String i, Id roleId, Id profileId,String storeNum,String status){
        User returnUser = new User();
        returnUser.FirstName = storeNum + ' TestUps' + i;
        returnUser.LastName = storeNum + 'UpsConsultant' + i;
        returnUser.Email = 'TstSlsCslt'+i+'@carmax.com';
        returnUser.UserName = 'TestUpsconsultant'+i+'@checkedinPoint.com';
        returnUser.Alias = 'tups'+i;
        returnUser.UserRoleId = roleId;
        returnUser.ProfileId = profileId;
        returnUser.TimeZoneSidKey = 'America/New_York';
        returnUser.LocaleSidKey = 'en_US';
        returnUser.EmailEncodingKey = 'UTF-8';
        returnUser.LanguageLocaleKey = 'en_US';
        returnUser.StoreNum__c = storeNum;
        //returnUser.Active_Location__c = storeNum;
        //returnUser.Status__c = status;

        return returnUser;
    }
    
    @isTest static void PostCallNoAccountDatapointPorvided(){
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"eta":{"minutesAway":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
    @isTest static void PostCallNoKMXIdProvided(){
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"eta":{"minutesAway":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
    @isTest static void PostCallNoETAProvided(){
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
    public static List<Account> createAccounts(Integer numAccts) {
        List<Account> accts = new List<Account>();
        List<RecordType> personAccts = [SELECT Id, sObjectType, Name FROM RecordType WHERE Name='Person Account' AND sObjectType = 'Account' LIMIT 1];
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account();
            //a.RecordTypeId = personAccts[0].Id;
            a.Name = 'TestAccount' + i;
            a.My_KMX_Id__c = '2a79a489-e841-4be5' ; //-a661-8fade14556e5
            accts.add(a);
        }
        
        return accts;
    }
    @isTest static void PostCallReturnsNoContentWhenPhoneNumberIsConnectedToMultipleCustomer(){
        Account[] accts = createAccounts(2);
        insert accts;
        
        Test.startTest();
        
       RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"eta":{"minutesAwayFromDestination":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
    @isTest static void PostCallWithCustomerNoOppty(){
        Account[] accts = createAccounts(1);
        insert accts;
        
        Test.startTest();
        
       RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"eta":{"minutesAwayFromDestination":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
     Public static List<Opportunity> createOpportunitiesForAccount (Integer numOppsPerAcct, List<Account> accts){
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i=0;i<accts.size();i++) {
            Account acct = accts[i];
            for (Integer j=0;j<numOppsPerAcct;j++) {
                opps.add(new Opportunity(Name=acct.Name + ' Opportunity ' + j,
                                       StageName='Prospecting',
                                       CloseDate=System.today().addMonths(1),
                                       AccountId=acct.Id));
            }
        }
        return opps;
    }
    @isTest static void PostCallWithCustomerMultiOppty(){
        Account[] accts = createAccounts(1);
        insert accts;
        Opportunity[] opps = createOpportunitiesForAccount(2, accts);
        insert opps;
        Test.startTest();
        
       RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"eta":{"minutesAwayFromDestination":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
    @isTest static void PostCallWithCustomerOpptyNoEvent(){
        Account[] accts = createAccounts(1);
        insert accts;
        Opportunity[] opps = createOpportunitiesForAccount(1, accts);
        insert opps;
        Test.startTest();
        
       RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"eta":{"minutesAwayFromDestination":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        system.assertEquals(400, res.statusCode);
        Test.stopTest();
    }
    @isTest static void PostCallWithCustomerOpptyEvent(){
        Account[] accts = createAccounts(1);
        insert accts;
        Opportunity[] opps = createOpportunitiesForAccount(1, accts);
        insert opps;
        List<Event> events = createEventsForOpportunity(1,opps,'Browse', null);
        insert events;
        Test.startTest();
        
       RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/appointment/check-in/';
        req.httpMethod = 'POST';
        req.requestBody =blob.valueOf('{"specversion":"1.0","type":"com.radar.customer.trip.started.v1","source":"https://mobileapps-functions-dev.azurewebsites.net","id":"acdb6ecd-07fc-4dca-9b8a-1f946347a8d2","time":"2021-04-23T18:00:50.6119752Z","data":{"identities":[{"type":"ciamId","value":"2a79a489-e841-4be5"}],"eta":{"minutesAwayFromDestination":20,"milesAway":7},"storeId":"7101"}}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        ISX_AppointmentRadarETA.appointmentRadarETA();
        
        ISX_AppointmentRadarETA.appointmentRadarETA();
        
        //system.assertEquals(500, res.statusCode);
        Test.stopTest();
    } 
    Public static List<Event> createEventsForOpportunity (Integer numEventPerOpp, List<Opportunity> opps, string appType, string leadType){
        List<Event> apps = new List<Event>();
        for (Integer i=0; i<opps.size(); i++) {
            Opportunity opp = opps[i];
            for(Integer j=0; j<numEventPerOpp; j++){
                apps.add(new Event(WhatId = opp.Id,
                                  Appointment_Status__c = 'Open',
                                  StartDateTime = System.now(),
                                  DurationInMinutes = 2,
                                  Appointment_Type__c = appType,
                                  Lead_Type__c = leadType));
            }  
        }
        
        return apps;
    }
    
}