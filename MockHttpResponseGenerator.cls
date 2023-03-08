@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    
    public Integer STATUS_CODE;
    
    public Map<Integer,String> mapStatusResponse=new Map<Integer,String>{
            400 => Constants.RESPONSE_400,
            401 => '',
            404 => '',
            409 => Constants.RESPONSE_409,
            403 => Constants.RESPONSE_403,
            202 => Constants.RESPONSE_202
    };
        
    public MockHttpResponseGenerator(Integer STATUS_CODE){
        this.STATUS_CODE = STATUS_CODE;
    }
    
                
    global HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('https://example.com/example/test', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if(mapStatusResponse.containsKey(STATUS_CODE)){
            res.setBody(mapStatusResponse.get(STATUS_CODE));
        }else{
            res.setBody('');
        }
        
        res.setStatusCode(STATUS_CODE);
        return res;
    }
}