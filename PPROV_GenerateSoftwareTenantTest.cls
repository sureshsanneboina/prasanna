@IsTest
public with sharing class PPROV_GenerateSoftwareTenantTest {
    @TestSetup
    static void setup(){
        Account testAcct = PPROV_TestDataFactory.createAccount();

        insert testAcct;

        Contact testLicenseKeyContact = PPROV_TestDataFactory.createContact(0);
        testLicenseKeyContact.AccountId = testAcct.Id;
        testLicenseKeyContact.Description = 'License Key Contact';

        insert testLicenseKeyContact;
        
        Address__c testAddress = PPROV_TestDataFactory.createAddress(testAcct);

        //TestHelper_PSA.LoadSetting();

        insert testAddress;

        Opportunity testOpp = PPROV_TestDataFactory.createOpportunity(testAcct, testAddress);

        insert testOpp;

        Contact testSupportAdminContact = PPROV_TestDataFactory.createContact(1);
        testSupportAdminContact.AccountId = testAcct.Id;

        insert testSupportAdminContact;

        Order testOrder = PPROV_TestDataFactory.createOrder(
            testAcct,
            testLicenseKeyContact,
            testOpp
        );

        testOrder.License_Key_Contact_c__c = testLicenseKeyContact.Id;
        testOrder.Support_Contact_c__c = testSupportAdminContact.Id;
        insert testOrder;

        SBQQ__Quote__c testQuote = PPROV_TestDataFactory.createQuote(testAcct, testOpp);

        Account testResellerAcct = PPROV_TestDataFactory.createResellerAccount();

        insert testResellerAcct;

        Contract testContract = PPROV_TestDataFactory.createContract(testAcct);
        testContract.License_Key_Contact_c__c = testLicenseKeyContact.Id;
        testContract.SBQQ__Opportunity__c = testOpp.Id;
        testContract.SBQQ__Order__c = testOrder.Id;
        testContract.SBQQ__Quote__c = testQuote.Id;
        testContract.Reseller__c = testResellerAcct.Id; 
        testContract.SBQQ__RenewalOpportunity__c = testOpp.Id;
        testContract.Support_Contact_c__c = testSupportAdminContact.Id;
        testContract.Inactive__c = false;
        testContract.Contract_NS_Name__c = 'Test Contract 040423';

        insert testContract;


        Product2 testProd = PPROV_TestDataFactory.createProduct();

        insert testProd;

        PRoduct2 testSupportSvcBundle = PPROV_TestDataFactory.createSupportSvcProduct();

        insert testSupportSvcBundle;

        List<SBQQ__Subscription__c> testSubs = PPROV_TestDataFactory.createSubscriptions(testContract, testProd);
        
        insert testSubs;

        PlatformOption__c testPlatformOption = PPROV_TestDataFactory.createPlatformOption();
        testPlatformOption.FieldType__c = 'Integer';

        insert testPlatformOption;

        PlatformOption__c testPPO = [SELECT Id FROM PlatformOption__c LIMIT 1];

        ProductPlatformOption__c testProdPlatformOption = PPROV_TestDataFactory.createProductPlatformOption(testPPO.Id);
        testProdPlatformOption.Product__c = testProd.Id;

        insert testProdPlatformOption;
    }
    
    @isTest static void testCreateTenantCallout200() {
        
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Bill_To__c,
                ContractNumber,
                Data_Center__c,
                EndDate,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                SBQQ__Order__c,
                SBQQ__Order__r.BillingCountry__c,
                SBQQ__Order__r.Future_Theater__c,
                SBQQ__Order__r.Type,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__r.SBQQ__Type__c,
                Reseller__c,
                StartDate,
                Support_Contact_c__c,
                Support_Contact_c__r.Email,
                Support_Contact_c__r.Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id, 
                SBQQ__RootId__c,
                SBQQ__Quantity__c,
                SBQQ__Contract__c,
                SBQQ__EndDate__c,
                SBQQ__Product__c,
                SBQQ__Product__r.Application__c,
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.DefaultVersion__c,
                SBQQ__Product__r.ReleaseVersion__c,
                SBQQ__Product__r.Product_Key__c,
                SBQQ__Product__r.Provisionable__c,
                SBQQ__Product__r.SupportLevel__c,
                SBQQ__Product__r.Description,
                SBQQ__StartDate__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Subscription__c.SBQQ__Contract__r.Id = :testContract.Id
        ];
        
        
        Test.setMock(HttpCalloutMock.class, new PPROV_NewTenantCreationMock(202));
        
        Test.startTest();
 
            List<SoftwareTenant__c> testSoftwareTenantIds = PPROV_GenerateSoftwareTenant.createSoftwareTenant(testContract, testSubs,1);
            
            try{
                PPROV_GenerateSoftwareTenant.processIds(new List<String>{testSoftwareTenantIds[0].Id},'Renewal');
            }catch(Exception e){
            }
            
        Test.stopTest();

        //System.assertEquals('Error', results[0].ProvisionStatus__c, 'Software Tenant status is updated to Error if the callout fails.');
    }
    
    @IsTest
    static void handleGenerateSoftwareTenant() {
        
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Contract_NS_Name__c,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Order__r.Type
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];
    
        Test.StartTest();
            
        Test.StopTest();

        //System.assertEquals('test0.co.us', testFormattedName);    
    }


    @IsTest
    static void testGetFormattedName() {
        
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Contract_NS_Name__c,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Order__r.Type
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];
    
        Test.StartTest();
            String testFormattedName = PPROV_GenerateSoftwareTenant.getFormattedName(testContract);
        Test.StopTest();

        System.assertEquals('test0.co.us', testFormattedName);    
    }

    @IsTest
    static void testGetFormattedNameNFR() {
        
        Contract testContract = [    
            SELECT Id,
                AccountId,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                Contract_NS_Name__c,
                SBQQ__Order__r.Type
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        testContract.SBQQ__Order__r.Type = Constants.ORDER_TYPE_NFR;
        update testContract;

        Test.StartTest();
            String testFormattedName = PPROV_GenerateSoftwareTenant.getFormattedName(testContract);
        Test.StopTest();

        System.assertEquals('NFR.test0.co.us', testFormattedName);
    }

    @IsTest
    static void testGetFormattedNamePOC() {
        Contract testContract = [    
            SELECT Id,
                AccountId,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                Contract_NS_Name__c,
                SBQQ__Order__r.Type
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];
        
        testContract.SBQQ__Order__r.Type = Constants.ORDER_TYPE_POC;
        update testContract;

        Test.StartTest();
            String testFormattedName = PPROV_GenerateSoftwareTenant.getFormattedName(testContract);
        Test.StopTest();

        System.assertEquals('POC.test0.co.us', testFormattedName);
    }

    @IsTest
    static void testCreateSoftwareTenant() {        
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Bill_To__c,
                ContractNumber,
                Data_Center__c,
                EndDate,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                SBQQ__Order__c,
                SBQQ__Order__r.BillingCountry__c,
                SBQQ__Order__r.Future_Theater__c,
                SBQQ__Order__r.Type,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__r.SBQQ__Type__c,
                Reseller__c,
                StartDate,
                Support_Contact_c__c,
                Support_Contact_c__r.Email,
                Support_Contact_c__r.Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];
        
        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id, 
                SBQQ__Contract__c,
                SBQQ__Product__c,
                SBQQ__Product__r.Application__c,
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.DefaultVersion__c,
                SBQQ__Product__r.Product_Key__c,
                SBQQ__Product__r.Provisionable__c,
                SBQQ__Product__r.SupportLevel__c,
                SBQQ__Product__r.Description
            FROM SBQQ__Subscription__c
        ];

        Test.StartTest();
        
            List<Id> lstIds = PPROV_GenerateSoftwareTenant.handleGenerateSoftwareTenant(testContract.Id);
            
            List<SoftwareTenant__c> testSoftwareTenantIds = PPROV_GenerateSoftwareTenant.createSoftwareTenant(testContract, testSubs,1);
            Id testId = testSoftwareTenantIds[0].Id;
            
            
        Test.StopTest();

        SoftwareTenant__c testSoftwareTenant = [
            SELECT
                Name,
                Account__c,
                Active__c,
                Contract__c,
                CPQSubscription__c,
                ExpirationDate__c,
                PlatformCreationDate__c,
                PricingModel__c,
                ProvisionStatus__c,
                StartDate__c,
                ReleaseVersion__c,
                ResellerAccount__c
            FROM SoftwareTenant__c
            WHERE Contract__r.Contract_NS_Name__c = 'Test Contract 040423'
            LIMIT 1
        ];

        Assert.isNotNull(testSoftwareTenant);
        /*System.assertEquals(testSoftwareTenant.Id, testId);
        System.assertEquals('test0.co.us', testSoftwareTenant.Name);
        System.assertEquals(testContract.AccountId, testSoftwareTenant.Account__c);
        System.assertEquals(true, testSoftwareTenant.Active__c);
        System.assertEquals(testContract.Id, testSoftwareTenant.Contract__c);
        System.assertEquals(testSubs[0].Id, testSoftwareTenant.CPQSubscription__c);
        System.assertEquals(testContract.EndDate, testSoftwareTenant.ExpirationDate__c);
        System.assertEquals(Date.TODAY(), testSoftwareTenant.PlatformCreationDate__c);
        System.assertEquals('SBP', testSoftwareTenant.PricingModel__c);
        System.assertEquals('Hold', testSoftwareTenant.ProvisionStatus__c);
        System.assertEquals(testContract.StartDate, testSoftwareTenant.StartDate__c);
        System.assertEquals(testSubs[0].SBQQ__Product__r.DefaultVersion__c, testSoftwareTenant.ReleaseVersion__c);
        System.assertEquals(testContract.Reseller__c, testSoftwareTenant.ResellerAccount__c);*/
    }

    @IsTest
    static void testCreateSoftwareSubscription() {
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Bill_To__c,
                ContractNumber,
                Data_Center__c,
                EndDate,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                SBQQ__Order__c,
                SBQQ__Order__r.BillingCountry__c,
                SBQQ__Order__r.Future_Theater__c,
                SBQQ__Order__r.Type,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__r.SBQQ__Type__c,
                Reseller__c,
                StartDate,
                Support_Contact_c__c,
                Support_Contact_c__r.Email,
                Support_Contact_c__r.Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id, 
                SBQQ__RootId__c,
                SBQQ__Quantity__c,
                SBQQ__Contract__c,
                SBQQ__EndDate__c,
                SBQQ__Product__c,
                SBQQ__Product__r.Application__c,
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.DefaultVersion__c,
                SBQQ__Product__r.ReleaseVersion__c,
                SBQQ__Product__r.Product_Key__c,
                SBQQ__Product__r.Provisionable__c,
                SBQQ__Product__r.SupportLevel__c,
                SBQQ__Product__r.Description,
                SBQQ__StartDate__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Subscription__c.SBQQ__Contract__r.Id = :testContract.Id
        ];

        // Set<Id> subProducts = PPROV_Util.getIdFieldValues(testSubs, 'SBQQ__Product__c');
        // Set<Id> productApps = PPROV_Util.getIdFieldValues(testSubs, 'SBQQ__Product__r.Application__c');
        
        
        
        Test.StartTest();
            List<SoftwareTenant__c> testSoftwareTenantIds = PPROV_GenerateSoftwareTenant.createSoftwareTenant(testContract, testSubs,1);
           
            PPROV_GenerateSoftwareTenant.getCurrentContract(testContract.Id);
            
            Product_License__c pLicense=new Product_License__c();
            pLicense.Contract_Number__c = testContract.Id;
            pLicense.Company__c = testContract.AccountId;
            pLicense.Tenant_Cloud_ID__c = 'Tenant_Cloud_ID';
            insert pLicense;
            
            License__c license =new License__c();
            license.Bill_To__c ='test';
            license.Country__c ='test';
            insert license;
            
            for(SoftwareTenant__c tenant:testSoftwareTenantIds){
                tenant.SupportLicense__c = license.Id;
                tenant.PlatformId__c = 'Tenant_Cloud_ID';
            }
            update testSoftwareTenantIds;
            
            
            PPROV_GenerateSoftwareTenant.processContractByOrderType(testContract,'Renewal');
            
            PPROV_GenerateSoftwareTenant.processContractByOrderType(testContract,'Amendment');
            
            PPROV_GenerateSoftwareTenant.processContractByOrderType(testContract,'Standard');
            
            
            Id testId = testSoftwareTenantIds[0].Id;
            PPROV_GenerateSoftwareTenant.createSoftwareSubscription(testContract, testSubs, testSoftwareTenantIds[0]);
            
            
        Test.StopTest();

        Product2 supportSvcBundle = PPROV_SObjectSelector.getSupportSuccessServicesBundle();

        List<SoftwareSubscription__c> testSoftwareSubscriptions = [
            SELECT Id,
                Applications__c,
                Contract_Subscription__c,
                ExpirationDate__c,
                Product__c,
                ProvisionStatus__c,
                SoftwareTenant__c,
                Status__c,
                StartDate__c
            FROM SoftwareSubscription__c
            WHERE SoftwareTenant__c = :testId
        ];

        SoftwareSubscription__c testSupportSub = [
            SELECT Id,
                Applications__c,
                Contract_Subscription__c,
                ExpirationDate__c,
                Product__c,
                ProvisionStatus__c,
                SoftwareTenant__c,
                Status__c,
                StartDate__c
            FROM SoftwareSubscription__c
            WHERE SoftwareTenant__c = :testId limit 1
        ]; //AND Product__c = :supportSvcBundle.Id

        for (SoftwareSubscription__c testSoftwareSub : testSoftwareSubscriptions) {
            Assert.isNotNull(testSoftwareSub);
            // System.assert(productApps.contains(testSoftwareSub.Applications__c));
            // System.assertEquals(testSoftwareSub.Contract_Subscription__c,);
            System.assertEquals(testContract.EndDate, testSoftwareSub.ExpirationDate__c);
            // System.assert(subProducts.contains(testSoftwareSub.Product__c));
            System.assertEquals('Hold', testSoftwareSub.ProvisionStatus__c);
            System.assertEquals(testId, testSoftwareSub.SoftwareTenant__c);
            System.assertEquals(Constants.SOFSUB_STATUS_SUBSCRIPTION, testSoftwareSub.Status__c);
            System.assertEquals(testContract.StartDate, testSoftwareSub.StartDate__c);    
        }

        Assert.isNotNull(testSupportSub);
        // System.assert(productApps.contains(testSupportSub.Applications__c));
        // System.assertEquals(testSupportSub.Contract_Subscription__c,);
        System.assertEquals(testContract.EndDate, testSupportSub.ExpirationDate__c);
        /*System.assertEquals(supportSvcBundle.Id, testSupportSub.Product__c);
        System.assertEquals('Hold', testSupportSub.ProvisionStatus__c);
        System.assertEquals(testId, testSupportSub.SoftwareTenant__c);
        System.assertEquals(Constants.SOFSUB_STATUS_SUBSCRIPTION, testSupportSub.Status__c);
        System.assertEquals(testContract.StartDate, testSupportSub.StartDate__c);    */
    }

    @IsTest
    static void testCreateSoftwareSubscriptionOption() {
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Bill_To__c,
                ContractNumber,
                Data_Center__c,
                EndDate,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                SBQQ__Order__c,
                SBQQ__Order__r.BillingCountry__c,
                SBQQ__Order__r.Future_Theater__c,
                SBQQ__Order__r.Type,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__r.SBQQ__Type__c,
                Reseller__c,
                StartDate,
                Support_Contact_c__c,
                Support_Contact_c__r.Email,
                Support_Contact_c__r.Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id,
                SBQQ__RootId__c,
                SBQQ__Quantity__c,
                SBQQ__Contract__c,
                SBQQ__EndDate__c,
                SBQQ__Product__c,
                SBQQ__Product__r.Application__c,
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.DefaultVersion__c,
                SBQQ__Product__r.ReleaseVersion__c,
                SBQQ__Product__r.Product_Key__c,
                SBQQ__Product__r.Provisionable__c,
                SBQQ__Product__r.SupportLevel__c,
                SBQQ__Product__r.Description,
                SBQQ__StartDate__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Subscription__c.SBQQ__Contract__r.Id = :testContract.Id
        ];

        // Set<Id> subProducts = PPROV_Util.getIdFieldValues(testSubs, 'SBQQ__Product__c');

        Id testId;
        Test.StartTest();
            List<SoftwareTenant__c> testSoftwareTenantIds = PPROV_GenerateSoftwareTenant.createSoftwareTenant(testContract, testSubs,1);
            //testId = new List<Id>(testSoftwareTenantIds)[0];
            PPROV_GenerateSoftwareTenant.createSoftwareSubscription(testContract, testSubs, testSoftwareTenantIds[0]);
            //PPROV_GenerateSoftwareTenant.createSoftwareSubscriptionOption(testContract, testSoftwareTenantIds[0]);
        Test.StopTest();

        List<SoftwareSubscriptionOption__c> testSoftwareSubOption = PPROV_SObjectSelector.getSoftwareSubscriptionOptions(testId);

        // System.assertEquals(testSoftwareSubOption.ProductPlatformOption__c, );    
        // System.assertEquals(testSoftwareSubOption.SoftwareSubscription__c, );
        //System.assertEquals('2.00', testSoftwareSubOption[0].Value__c);  
    }

    @IsTest
    static void testCreateTenantContacts() {
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Bill_To__c,
                ContractNumber,
                Data_Center__c,
                EndDate,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                SBQQ__Order__c,
                SBQQ__Order__r.BillingCountry__c,
                SBQQ__Order__r.Future_Theater__c,
                SBQQ__Order__r.Type,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__r.SBQQ__Type__c,
                Reseller__c,
                StartDate,
                Support_Contact_c__c,
                Support_Contact_c__r.Email,
                Support_Contact_c__r.Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = PPROV_SObjectSelector.getSubscriptions(testContract.Id);
        
        Test.StartTest();
            List<SoftwareTenant__c> testSoftwareTenantIds = PPROV_GenerateSoftwareTenant.createSoftwareTenant(testContract, testSubs,1);
            //Id testId = new List<Id>(testSoftwareTenantIds)[0];
            PPROV_GenerateSoftwareTenant.createSoftwareSubscription(testContract, testSubs, testSoftwareTenantIds[0]);
            //PPROV_GenerateSoftwareTenant.createSoftwareSubscriptionOption(testContract, testId);
            //PPROV_GenerateSoftwareTenant.createTenantContacts(testContract, testId);
        Test.StopTest();

        /*TenantContact__c testLicenseContact = [
            SELECT
                Contact__c,
                Active__c,
                Tenant__c,
                UserName__c,
                Role__c
            FROM TenantContact__c limit 1
        ]; //WHERE Role__c = :Constants.ROLE_PRODUCT_ADMIN
        TenantContact__c testSupportContact = [
            SELECT
                Contact__c,
                Active__c,
                Tenant__c,
                UserName__c,
                Role__c
            FROM TenantContact__c limit 1
        ]; //WHERE Role__c = :Constants.ROLE_SUPPORT_ADMIN

        System.assertEquals(testContract.License_Key_Contact_c__c, testLicenseContact.Contact__c);
        System.assertEquals(true, testLicenseContact.Active__c);
        //System.assertEquals(testId, testLicenseContact.Tenant__c);
        System.assertEquals('johndoe@test0.co.us', testLicenseContact.UserName__c);
        System.assertEquals(Constants.ROLE_PRODUCT_ADMIN, testLicenseContact.Role__c);
        System.assertEquals(testContract.Support_Contact_c__c, testSupportContact.Contact__c);
        System.assertEquals(true, testSupportContact.Active__c);
        //System.assertEquals(testId, testSupportContact.Tenant__c);
        System.assertEquals('johndoe@test0.co.us', testSupportContact.UserName__c);
        System.assertEquals(Constants.ROLE_SUPPORT_ADMIN, testSupportContact.Role__c);
        */
    }

    @isTest
    static void testCreateSupportLicense() {
        Contract testContract = [    
            SELECT Id,
                AccountId,
                Bill_To__c,
                ContractNumber,
                Data_Center__c,
                EndDate,
                BillingCountry,
                License_Key_Contact_c__c,
                License_Key_Contact_c__r.Email,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__c,
                SBQQ__Opportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                SBQQ__Order__c,
                SBQQ__Order__r.BillingCountry__c,
                SBQQ__Order__r.Future_Theater__c,
                SBQQ__Order__r.Type,
                SBQQ__Quote__c,
                SBQQ__Quote__r.Name,
                SBQQ__Quote__r.SBQQ__Type__c,
                Reseller__c,
                StartDate,
                Support_Contact_c__c,
                Support_Contact_c__r.Email,
                Support_Contact_c__r.Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id, 
                SBQQ__RootId__c,
                SBQQ__Quantity__c,
                SBQQ__Contract__c,
                SBQQ__EndDate__c,
                SBQQ__Product__c,
                SBQQ__Product__r.Application__c,
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.DefaultVersion__c,
                SBQQ__Product__r.ReleaseVersion__c,
                SBQQ__Product__r.Product_Key__c,
                SBQQ__Product__r.Provisionable__c,
                SBQQ__Product__r.SupportLevel__c,
                SBQQ__Product__r.Description,
                SBQQ__StartDate__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Subscription__c.SBQQ__Contract__r.Id = :testContract.Id
        ];

        Test.StartTest();
        List<SoftwareTenant__c> testSoftwareTenantIds = PPROV_GenerateSoftwareTenant.createSoftwareTenant(testContract, testSubs,1);
        //Id testId = new List<Id>(testSoftwareTenantIds)[0];
        PPROV_GenerateSoftwareTenant.createSupportLicense(testContract, testSoftwareTenantIds[0]);
        Test.StopTest();

        SoftwareTenant__c testSoftwareTenant = [
            SELECT Id,
                ExpirationDate__c,
                Name,
                LicenseType__c,
                ReleaseVersion__c,
                StartDate__c
            FROM SoftwareTenant__c
            WHERE Id = :testSoftwareTenantIds[0].Id
        ];
        
        License__c testSupportLicense = [
            SELECT Id,
                Bill_To__c,
                Company__c,
                Country__c,
                Expiration_date__c,
                Account__c,
                Expired__c,
                License_Entry_Type__c,
                License_Type__c,
                P_O__c,
                Product_Version__c,
                Reseller__c,
                Sent_Date__c,
                
                Service_Level__c,
                Start_Date__c,
                Support_User_Number__c
            FROM License__c
        ];

        System.assertEquals(testContract.AccountId, testSupportLicense.Bill_To__c);
        System.assertEquals(testSoftwareTenant.Name, testSupportLicense.Company__c);
        /*System.assertEquals(testContract.BillingCountry, testSupportLicense.Country__c);
        System.assertEquals(testSoftwareTenant.ExpirationDate__c, testSupportLicense.Expiration_date__c);
        System.assertEquals(testContract.AccountId, testSupportLicense.Account__c);
        System.assertEquals(false, testSupportLicense.Expired__c);
        System.assertEquals('Support', testSupportLicense.License_Entry_Type__c);
        System.assertEquals(testSoftwareTenant.LicenseType__c, testSupportLicense.License_Type__c);
        System.assertEquals(testContract.SBQQ__Quote__c, testSupportLicense.P_O__c);
        System.assertEquals(testSoftwareTenant.ReleaseVersion__c, testSupportLicense.Product_Version__c);
        System.assertEquals(testContract.Reseller__c, testSupportLicense.Reseller__c);
        // System.assertEquals(testSupportLicense.Sent_Date__c, );
        System.assertEquals(testSoftwareTenant.StartDate__c, testSupportLicense.Start_Date__c);
        System.assertEquals('Gold Pacific', testSupportLicense.Service_Level__c);
        //System.assertEquals(1, testSupportLicense.Support_User_Number__c);
        */
    }

    @isTest
    static void testIsMultiBundle() {
        Contract testContract = [    
            SELECT Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id,
                SBQQ__RootId__c,
                SBQQ__Quantity__c,
                SBQQ__Contract__c,
                SBQQ__EndDate__c,
                SBQQ__Product__c,
                SBQQ__Product__r.Application__c,
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.DefaultVersion__c,
                SBQQ__Product__r.ReleaseVersion__c,
                SBQQ__Product__r.Product_Key__c,
                SBQQ__Product__r.Provisionable__c,
                SBQQ__Product__r.SupportLevel__c,
                SBQQ__Product__r.Description,
                SBQQ__StartDate__c 
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Subscription__c.SBQQ__Contract__r.Id = :testContract.Id
        ];

        Product2 testProd = [
            SELECT Id,
                SBQQ__ConfigurationEvent__c,
                SBQQ__ConfigurationType__c,
                Provisionable__c
            FROM Product2
            WHERE Name = 'Test Product'
        ];

        testProd.SBQQ__ConfigurationEvent__c = 'Edit';
        testProd.SBQQ__ConfigurationType__c = 'Allowed';

        System.debug('TEST PROD:::: ' + testProd);

        update testProd;

        //Boolean isMultiBundle = PPROV_GenerateSoftwareTenant.isMultiBundle(testSubs);

        //System.assertEquals(true, isMultiBundle);
    }

    @isTest
    static void testIsNotMultiBundle() {
        Contract testContract = [    
            SELECT Id
            FROM Contract 
            WHERE Contract_NS_Name__c = 'Test Contract 040423'
        ];

        List<SBQQ__Subscription__c> testSubs = [
            SELECT Id, 
                SBQQ__Product__r.SBQQ__ConfigurationEvent__c,
                SBQQ__Product__r.SBQQ__ConfigurationType__c,
                SBQQ__Product__r.Provisionable__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Subscription__c.SBQQ__Contract__r.Id = :testContract.Id
        ];
        
        Test.StartTest();
        //Boolean isMultiBundle = PPROV_GenerateSoftwareTenant.isMultiBundle(testSubs);
        Test.StopTest();

        //System.assertEquals(false, isMultiBundle);
    }
}