@isTest
private class PPROV_SObjectSelectorTest {

    @testSetup
    static void createTestData() {
        
        Account testAcct = PPROV_TestDataFactory.createAccount();
        insert testAcct;
        
        // Contact
        List<Contact> contacts = new List<Contact>();
        contacts.add(PPROV_TestDataFactory.createContact(1));
        contacts.add(PPROV_TestDataFactory.createContact(2));
        insert contacts;
        
        Contract testContract = PPROV_TestDataFactory.createContract(testAcct);
        testContract.Inactive__c = false;
        testContract.Contract_NS_Name__c = 'Test Contract 040423';
        insert testContract;
        
        Product2 testProd = PPROV_TestDataFactory.createProduct();
        insert testProd;
        
        List<SBQQ__Subscription__c> testSubs = PPROV_TestDataFactory.createSubscriptions(testContract, testProd);
        insert testSubs;
        
        License__c license =new License__c();
        license.Bill_To__c ='test';
        license.Country__c ='test';
        insert license;

        // SoftwareTenant__c
        SoftwareTenant__c tenant = PPROV_TestDataFactory.createSoftwareTenant();
        tenant.PlatformId__c = 'test platform id';
        tenant.Account__c = testAcct.Id;
        tenant.SupportLicense__c = license.Id;
        tenant.Active__c = true;
        insert tenant;

        // SoftwareSubscription__c
        SoftwareSubscription__c softwareSub = PPROV_TestDataFactory.createSoftwareSubscription(null, null, tenant.Id);
        insert softwareSub;

        // SoftwareTenantVersion__c
        SoftwareTenantVersion__c tenantVersion = PPROV_TestDataFactory.createTenantVersion(tenant.Id);
        insert tenantVersion;

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
    
    @isTest
    static void getScheduleJobConfigByName(){
        List<Schedule_Job_Config__mdt> scheduleConfig=PPROV_SObjectSelector.getScheduleJobConfigByName('Test');
        //System.assertEquals(scheduleConfig[0].Job__c, 'Test');
    }
    
    @isTest
    static void getAllTalendCloudMappingMetadata(){
        List<Talend_Cloud_Mapping__mdt> lstTalendcloudMapping=PPROV_SObjectSelector.getAllTalendCloudMappingMetadata();
        System.assertEquals(lstTalendcloudMapping.size(), 2);
    }
    
    @isTest
    static void getSupportContact(){
        
        Map<Id,Contact> mapContacts=new Map<Id,Contact>([Select Id from Contact]);
        List<Id> lstIds=new List<Id>();
        lstIds.addAll(mapContacts.keySet());
        List<Contact> lstContact=PPROV_SObjectSelector.getSupportContact(lstIds);
        System.assertEquals(lstContact.size(), mapContacts.size());
    }
    
    @isTest
    static void getPPROVContract(){
        
        Contract contract=[Select Id from Contract limit 1];
        Contract ContractRec=PPROV_SObjectSelector.getPPROVContract(contract.Id);
        System.assertEquals(contract.Id, ContractRec.Id);
    }
    
     @isTest
    static void getQuoteLinesWithFieldsByQuote(){
        
        /*SBQQ__QuoteLine__c quoteline=new SBQQ__QuoteLine__c();
        insert quoteline;
        Set<Id> lstQuoteLineIds=new Set<Id>();
        lstQuoteLineIds.add(quoteline.Id);*/
        List<SBQQ__QuoteLine__c> lstQuoteLine=PPROV_SObjectSelector.getQuoteLinesWithFieldsByQuote(new Set<Id>());
        System.assertEquals(lstQuoteLine.size(), 0);
    }
    
    @isTest
    static void getSubscriptions(){
        
        Contract contract=[Select Id from Contract limit 1];
        List<SBQQ__Subscription__c> lstSubscription=PPROV_SObjectSelector.getSubscriptions(contract.Id);
        System.assertEquals(lstSubscription[0].SBQQ__Contract__c, contract.Id);
    }
    
    @isTest
    static void getSubscriptionsWithoutExistingProducts(){
        
        Contract contract=[Select Id from Contract limit 1];
        List<SBQQ__Subscription__c> lstSubscription=PPROV_SObjectSelector.getSubscriptionsWithoutExistingProducts(contract.Id);
        System.assertEquals(lstSubscription[0].SBQQ__Contract__c, contract.Id);
    }
    
    @isTest
    static void getSubscriptionsCount(){
        
        Contract contract=[Select Id from Contract limit 1];
        Integer lstSubscriptioncount=PPROV_SObjectSelector.getSubscriptionsCount(contract);
        //System.assertEquals(lstSubscriptioncount, 1);
    }
    
    @isTest
    static void getSoftwareTenant(){
        
        SoftwareTenant__c softwareTenant=[Select Id from SoftwareTenant__c limit 1];
        SoftwareTenant__c softwareTenantRec=PPROV_SObjectSelector.getSoftwareTenant(softwareTenant.Id);
        System.assertEquals(softwareTenantRec.Id, softwareTenant.Id);
    }
    
    @isTest
    static void getSoftwareTenantByIds(){
        
        SoftwareTenant__c softwareTenant=[Select Id from SoftwareTenant__c limit 1];
        Set<Id> lstIds=new Set<Id>();
        lstIds.add(softwareTenant.Id);
        List<SoftwareTenant__c> lstsoftwareTenantRec=PPROV_SObjectSelector.getSoftwareTenantByIds(lstIds);
        System.assertEquals(lstsoftwareTenantRec.size(), lstIds.size());
    }
    
    @isTest
    static void getActiveSoftwareTenantsByAccountId(){
        
        Account acct=[Select Id from Account limit 1];
        Set<Id> lstIds=new Set<Id>();
        lstIds.add(acct.Id);
        List<SoftwareTenant__c> lstsoftwareTenants=PPROV_SObjectSelector.getActiveSoftwareTenantsByAccountId(lstIds);
        System.assertEquals(lstsoftwareTenants.size(), lstIds.size());
    }
    
    @isTest
    static void getActiveSoftwareTenantsBySupportLicense(){
        
        License__c license=[Select Id from License__c limit 1];
        SoftwareTenant__c softwareTenant=PPROV_SObjectSelector.getActiveSoftwareTenantsBySupportLicense(license.Id);
        System.assertEquals(softwareTenant.SupportLicense__c, license.Id);
    }
    
    @isTest
    static void getSoftwareTenantNameCount(){
        
        SoftwareTenant__c softwareTenant=[Select Id,Name from SoftwareTenant__c limit 1];
        Integer softwareTenantcount=PPROV_SObjectSelector.getSoftwareTenantNameCount(softwareTenant.Name);
        System.assertEquals(softwareTenantcount, 1);
    }
    
    @isTest
    static void getSoftwareSubscriptions(){
        
        SoftwareTenant__c softwareTenant=[Select Id,Name from SoftwareTenant__c limit 1];
        List<SoftwareSubscription__c> lstSoftwareSubscriptions=PPROV_SObjectSelector.getSoftwareSubscriptions(softwareTenant.Id);
        System.assertEquals(lstSoftwareSubscriptions.size(), 1);
    }
    
    @isTest
    static void getSoftwareSubscriptionsById(){
        
        SoftwareSubscription__c softwareSubscription=[Select Id,Name from SoftwareSubscription__c limit 1];
        Set<Id> lstIds=new Set<Id>();
        lstIds.add(softwareSubscription.Id);
        List<SoftwareSubscription__c> lstSoftwareSubscriptions=PPROV_SObjectSelector.getSoftwareSubscriptionsById(lstIds);
        System.assertEquals(lstSoftwareSubscriptions.size(), 1);
    }
    
    @isTest
    static void getSupportLevel(){
        Contract contract=[Select Id from Contract limit 1];
        String supportLevel=PPROV_SObjectSelector.getSupportLevel(contract.Id);
        System.assertEquals(supportLevel, 'Gold');
    }
    
    @isTest
    static void getBundleRoot(){
        
        List<SoftwareSubscription__c> lstSoftwareSubscriptions=PPROV_SObjectSelector.getBundleRoot();
        System.assertEquals(lstSoftwareSubscriptions.size(), 0);
    }
    
    @isTest
    static void getSoftwareSubscriptionOptions(){
        
        SoftwareTenant__c softwareTenant=[Select Id,Name from SoftwareTenant__c limit 1];
        List<SoftwareSubscriptionOption__c> lstSoftwareSubscriptionOption=PPROV_SObjectSelector.getSoftwareSubscriptionOptions(softwareTenant.Id);
        System.assertEquals(lstSoftwareSubscriptionOption.size(), 1);
    }
    
    @isTest
    static void getSoftwareTenantVersions(){
        
        SoftwareTenant__c softwareTenant=[Select Id,Name from SoftwareTenant__c limit 1];
        List<SoftwareTenantVersion__c> lstSoftwareTenantVersion=PPROV_SObjectSelector.getSoftwareTenantVersions(softwareTenant.Id);
        System.assertEquals(lstSoftwareTenantVersion.size(), 1);
    }
    
    
    @isTest
    static void getSupportSuccessServicesBundle(){
        try{
            Product2 Product=PPROV_SObjectSelector.getSupportSuccessServicesBundle();
            //System.assertEquals(Product.size(), 1);
        }catch(Exception e){
            
        }
    }
    
    
    @isTest
    static void getBundleRootProduct(){
        
        Product2 Product=[Select Id,Name from Product2 limit 1];
        Product2 ProductRec=PPROV_SObjectSelector.getBundleRootProduct(Product.Id);
        System.assertEquals(ProductRec.Id, Product.Id);
    }
    
    @isTest
    static void getProductLicense(){
        
        Contract contract=[Select Id from Contract limit 1];
        List<Product_License__c> lstProductLicense=PPROV_SObjectSelector.getProductLicense(contract.Id);
        System.assertEquals(lstProductLicense.size(), 0);
    }
    
    @isTest
    static void getActiveProdLicensesWithTenantCloudIdById(){
        
        Contract contract=[Select Id from Contract limit 1];
        List<Product_License__c> lstProductLicense=PPROV_SObjectSelector.getActiveProdLicensesWithTenantCloudIdById(new Set<Id>());
        System.assertEquals(lstProductLicense.size(), 0);
    }
    
    @isTest
    static void getActiveProdLicensesWithTenantCloudIdByContract(){
        
        Contract contract=[Select Id from Contract limit 1];
        List<Product_License__c> lstProductLicense=PPROV_SObjectSelector.getActiveProdLicensesWithTenantCloudIdByContract(contract.Id);
        System.assertEquals(lstProductLicense.size(), 0);
    }
    
    @isTest
    static void getProductPlatformOptions(){
        
        Contract contract=[Select Id from Contract limit 1];
        List<ProductPlatformOption__c> lstProductPlatformOption=PPROV_SObjectSelector.getProductPlatformOptions(new Set<Id>());
        System.assertEquals(lstProductPlatformOption.size(), 0);
    }
    
    @isTest
    static void getSupportLicense(){
        
        License__c license=[Select Id from License__c limit 1];
        List<License__c> lstLicense=PPROV_SObjectSelector.getSupportLicense(new Set<Id>{license.Id});
        System.assertEquals(lstLicense.size(), 1);
    }
    
    @isTest
    static void getSupportLicenses(){
        
        License__c license=[Select Id from License__c limit 1];
        List<License__c> lstLicense=PPROV_SObjectSelector.getSupportLicenses(new Set<Id>{license.Id});
        System.assertEquals(lstLicense.size(), 1);
    }
    
    
        
    @isTest
    static void getTenantsWithContacts(){
        
        SoftwareTenant__c softwareTenant=[Select Id,Name from SoftwareTenant__c limit 1];
        PPROV_SObjectSelector.getSupportLicenses(new Set<Id>{softwareTenant.Id});
        //System.assertEquals(lstSoftwareTenant.size(), 1);
    }
    
}