/***********************************************************************************************************************
Name          : PPROV_TalendProvisioningServiceTest
Author        : Slalom Team, Prasanna Nemalipuri
Date          : 03/14/23
@description  : Tests for PPROV_TalendProvisioningService methods.
***********************************************************************************************************************/
@isTest
private class PPROV_TalendProvisioningServiceTest {
    @testSetup
    static void createTestData() {
        // Contact
        List<Contact> contacts = new List<Contact>();
        contacts.add(PPROV_TestDataFactory.createContact(1));
        contacts.add(PPROV_TestDataFactory.createContact(2));
        insert contacts;

        // SoftwareTenant__c
        SoftwareTenant__c tenant = PPROV_TestDataFactory.createSoftwareTenant();
        insert tenant;

        // SoftwareSubscription__c
        SoftwareSubscription__c softwareSub = PPROV_TestDataFactory.createSoftwareSubscription(null, null, tenant.Id);
        insert softwareSub;

        // PlatformOption__c
        PlatformOption__c platformOpt = PPROV_TestDataFactory.createPlatformOption();
        insert platformOpt;

        // ProductPlatformOption__c
        ProductPlatformOption__c prodPlatformOpt = PPROV_TestDataFactory.createProductPlatformOption(platformOpt.Id);
        insert prodPlatformOpt;

        // SoftwareSubscriptionOption__c
        SoftwareSubscriptionOption__c softwareSubOption = 
            PPROV_TestDataFactory.createSoftwareSubscriptionOption(softwareSub.Id, prodPlatformOpt.Id);
        insert softwareSubOption;

        // TenantContact__c
        TenantContact__c tenantContact = PPROV_TestDataFactory.createTenantContact(tenant.Id, contacts[0].Id);
        insert tenantContact;
    }
    
    /**
     * @description Test Create Tenant OAuth for 200 response
     * @it asserts that we received expected response message for status code 400.
     * @it asserts that Software Tenant status is set to Error if the callout fails.
     */
    static TestMethod void testCreateTenantAuth200Update2Params() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        lstTenant[0].DataCenter__c ='test';
        update lstTenant;
        
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(202));
        Test.startTest();
            
            PPROV_TenantService.updateTenant(lstTenant[0].Id,'order type');
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Provisioned', results[0].ProvisionStatus__c, 'Software Tenant status is set to Error if the callout fails.');
    }
    
    /**
     * @description Test Create Tenant OAuth for 200 response
     * @it asserts that we received expected response message for status code 400.
     * @it asserts that Software Tenant status is set to Error if the callout fails.
     */
    static TestMethod void testCreateTenantAuth200Update() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(202));
        Test.startTest();
            PPROV_TenantService.updateTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is set to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant OAuth for 200 response
     * @it asserts that we received expected response message for status code 400.
     * @it asserts that Software Tenant status is set to Error if the callout fails.
     */
    static TestMethod void testCreateTenantAuth200() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        lstTenant[0].DataCenter__c ='test';
        update lstTenant;
        
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(202));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Provisioned', results[0].ProvisionStatus__c, 'Software Tenant status is set to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant OAuth for 401 response
     * @it asserts that Aura exception is thrown when Authentication response is not 200.
     */
    static TestMethod void testCreateTenantAuth401() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(401, true, false));
        Test.startTest();
            try {
                PPROV_TenantService.createTenant(lstTenant[0].Id);
            } catch (Exception ex) {
                System.assertEquals(
                    'Script-thrown exception',
                    ex.getMessage(),
                    'Aura exception is thrown when Authentication response is not 200.'
                );
            }
        Test.stopTest();
    }

    /**
     * @description Test Create Tenant callout for 200 response that generates an exception
     * @it asserts that Software Tenant status is updated to Error if the callout fails.
     */
    static TestMethod void testCreateTenantCallout202Exception() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(202, false, true));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
    
        System.assertEquals(1, results.size(), 
            'We expect a single tenant object returned from our testing');
        
            System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is set to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant callout for 400 response
     * @it asserts that Software Tenant status is updated to Error if the callout fails.
     */
    @isTest static void testCreateTenantCallout400() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(400));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is set to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant callout for 404 response
     * @it asserts that Software Tenant status is updated to Error if the callout fails.
     */
    @isTest static void testCreateTenantCallout404() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(404));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is updated to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant callout for 401 response
     * @it asserts that Software Tenant status is updated to Error if the callout fails.
     */
    @isTest static void testCreateTenantCallout401() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(401));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is updated to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant callout for 403 response
     * @it asserts that Software Tenant status is updated to Error if the callout fails.
     */
    @isTest static void testCreateTenantCallout403() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(403));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is updated to Error if the callout fails.');
    }

    /**
     * @description Test Create Tenant callout for 409 response
     * @it asserts that Software Tenant status is updated to Error if the callout fails.
     */
    @isTest static void testCreateTenantCallout409() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(409));
        Test.startTest();
            PPROV_TenantService.createTenant(lstTenant[0].Id);
        Test.stopTest();
        List<SoftwareTenant__c> results = 
            [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c WHERE Id = :lstTenant[0].Id];
        System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is updated to Error if the callout fails.');
    }
}