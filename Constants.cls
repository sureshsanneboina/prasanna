public class Constants
{
    public static String EX_STATUS_CODE='test';
    
    public static String EX_ERROR_MSG='test';
    
    public static String EX_ERROR_STAKE_TRACE='test';
    
    public static String RESPONSE_400 ='{"message": "Validation failed for one or more fields: [FieldError(fieldName=subscription.type, message=must not be blank, errorType=REQUIRED_VALUE)]"}';
        
	public static String RESPONSE_409 ='{"message": "Account \'alpha.co.uk\' already exists: null" }';
        
	public static String RESPONSE_403 ='{ "status": 403, "detail": "IP address not allowed" }';
        
    public static String RESPONSE_202 ='{'
        +'"id": "0030d5d8-f0bd-484f-8d70-76d0b83141a6",'
        +'"name": "alpha.co.uk2",'
        +'"displayName": "alpha.co.uk2",'
        +'"active": true,'
        +'"creationDate": "2023-03-06T23:47:11.258Z",'
        +'"subscription": {'
        +'"type": "Studio",'
        +'"status": "Subscription",'
        +'"startDate": "2022-06-01T00:00:00Z",'
        +'"expiryDate": "2023-05-31T00:00:00Z",'
        +'"options": {'
        +'"sso_enabled": true,'
        +'"apidt_max_users": 0,'
        +'"ipc_enabled": true,'
        +'"auditlogs_retention_days": 7,'
        +'"ip_whitelist_enabled": true,'
        +'"ipaas_max_studio_users": 3,'
        +'"ipaas_container_exclusive": false,'
        +'"ipaas_workspace_shared": true,'
        +'"ipaas_flows_scheduledexecution": true,'
        +'"ipaas_allow_actions": false,'
        +'"tds_max_stewardship_users": 2,'
        +'"tds_tasks_max_storage": 2,'
        +'"tmc_engine_credits": 90000,'
        +'"tdq_enabled": true,'
        +'"tdp_max_data_prep_users": 2,'
        +'"tmc_environments": 1,'
        +'"tmc_engine_cluster": true,'
        +'"tmc_export_logs_s3": true,'
        +'"tdataservice_enabled": false,'
        +'"dss_cloudengine_enabled": false,'
        +'"tmc_run_profile_standard": true,'
        +'"tmc_run_profile_bigdata": false,'
        +'"tmc_run_profile_advanced": false,'
        +'"dss_max_users": 3,'
        +'"hybrid_enabled": true,'
        +'"tdc_max_users": 0,'
        +'"tdp_dataset_provider": "catalog",'
        +'"tdp_sharing_impl": "sharing-common",'
        +'"minio_cloudstorage_enabled": true,'
        +'"has_privatelink_subscription": false,'
        +'"tdp_max_data_prep_storage": 2,'
        +'"tdp_max_data_prep_runs": 2,'
        +'"ipaas_max_users": 3,'
        +'"trr_enabled": true,'
        +'"tmc_max_service_accounts": 0,'
        +'"ipaas_static_ip": true,'
        +'"multitenant_dataplane_enabled": false'
        +'},'
        +'"applications": ['
        +'"DSS",'
        +'"STUDIO",'
        +'"TMC",'
        +'"TDP",'
        +'"TIPAAS",'
        +'"TDS"'
        +'],'
        +'"license": {'
        +'"licenseType": "Talend Integration Cloud",'
        +'"productKey": "TCP_DM",'
        +'"releaseVersion": "8.0.1"'
        +'}'
        +'},'
        +'"adminUser": {'
        +'"id": "275231e2-3ea3-471e-bc2f-6e385aa51e62",'
        +'"userName": "aaron.baker@alpha.co.uk2",'
        +'"lastName": "Baker",'
        +'"firstName": "Aaron",'
        +'"email": "aaron.baker@alpha.co.uk",'
        +'"password": ""'
        +'},'
        +'"licenseProvisioned": false'
        +'}';
    
    
}