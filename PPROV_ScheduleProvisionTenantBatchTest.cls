@isTest
private class PPROV_ScheduleProvisionTenantBatchTest {
    
    @testSetup
    static void createTestData() {
        SoftwareTenant__c sTenant=new SoftwareTenant__c(
                Active__c = true,
                LicenseType__c = 'Evaluation',
                Name = 'Test Tenant 1',
                PlatformCreationDate__c = System.today(),
                PricingModel__c = 'PAYG',
                ProvisionStatus__c = 'Not Provisioned',
                ReleaseVersion__c = '8.0.1',
                SupportLevel__c = 'Gold',
            	PlatformId__c ='123456'
            );
        insert sTenant;
        
        SoftwareSubscription__c subscription=new SoftwareSubscription__c(SoftwareTenant__c = sTenant.Id,ProvisionStatus__c ='Not Provisioned',
                                                                        StartDate__c = System.today());
        insert subscription;
    }
    
    @isTest static void testPPROV_ScheduleProvisionTenantBatch() {
        List<SoftwareTenant__c> lstTenant = [SELECT Id, ProvisionStatus__c FROM SoftwareTenant__c];
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(409));
        Test.startTest();
            PPROV_ScheduleProvisionTenantBatch ScheduleProvisionTenantBatch= new PPROV_ScheduleProvisionTenantBatch(); 
            String sch ='0 48 * * * ?'; 
            System.schedule('ScheduleProvisionTenantBatch', sch,ScheduleProvisionTenantBatch);
        Test.stopTest();
        
    }

}