/***********************************************************************************************************************
Name          : PPROV_SoftwareTenantTriggerHandlerTest
Author        : Slalom Team, Prasanna Nemalipuri
Date          : 05/24/23
@description  : Tests for PPROV_SoftwareTenantTriggerHandler & PPROV_SoftwareTenantTriggerHandlerHelper methods.
***********************************************************************************************************************/
@isTest
private class PPROV_SoftwareTenantTriggerHandlerTest {

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
    
    @isTest
    static void PPROV_SoftwareTenantTriggerHandlerTest() {
    
         Account testAcct = PPROV_TestDataFactory.createAccount();
        insert testAcct;
        
        Contact testLicenseKeyContact = PPROV_TestDataFactory.createContact(0);
        testLicenseKeyContact.AccountId = testAcct.Id;
        testLicenseKeyContact.Description = 'License Key Contact';
        insert testLicenseKeyContact;
        
        Address__c testAddress = PPROV_TestDataFactory.createAddress(testAcct);
        insert testAddress;

        Opportunity testOpp = PPROV_TestDataFactory.createOpportunity(testAcct, testAddress);
        insert testOpp;
        
        Order testOrder = PPROV_TestDataFactory.createOrder(testAcct,testLicenseKeyContact,testOpp);
        insert testOrder;
        
        
        Contract testContract = PPROV_TestDataFactory.createContract(testAcct);
        testContract.Inactive__c = false;
        testContract.Contract_NS_Name__c = 'Test Contract 040423';
        testContract.SBQQ__Order__c = testContract.SBQQ__Order__c = testOrder.Id;
        insert testContract;
        
         SoftwareTenant__c tenant = PPROV_TestDataFactory.createSoftwareTenant();
        tenant.PlatformId__c = 'test platform id';
        tenant.contract__c = testContract.Id;
        insert tenant;
        
         Test.startTest();
 
            
            tenant.ProvisionStatus__c ='test';
            update tenant;
            
            System.assertEquals(tenant.ProvisionStatus__c,'test');
            
        Test.stopTest();
    }
}