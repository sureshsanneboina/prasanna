@isTest
private class PPROV_TalendCRMLogBuilderTest
{
    @isTest
    static void process(){
        PPROV_TalendCRMLogBuilder builder=PPROV_TalendCRMLogBuilder.getInstance();
        builder.buildLog();
        builder.setStatusCode(200);
        
        builder.setErrorMessage('Test');
        builder.setPayload('Payload');
        builder.setProcessName('Test');
        builder.setResponse('test');
        
        List<String> lstString;
        try{
            String response=lstString[0];
        }catch(Exception e){
            builder.setException(e);
        }
        builder.setRecordId(UserInfo.getUserId());
        builder.buildLog();
    }
}