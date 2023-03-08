@isTest
private class CalloutClassTest {
    @isTest static void testCallout400() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400));
        
        HttpResponse res = CalloutClass.getInfoFromExternalService();
        System.assert(res.getHeader('Content-Type') == 'application/json');
        System.assertEquals(res.getBody(), Constants.RESPONSE_400);
        System.assertEquals(400, res.getStatusCode());
    }
    
    @isTest static void testCallout401() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(401));
        
        HttpResponse res = CalloutClass.getInfoFromExternalService();
        System.assert(res.getHeader('Content-Type') == 'application/json');
        System.assertEquals(res.getBody(), '');
        System.assertEquals(401, res.getStatusCode());
    }
    
    @isTest static void testCallout409() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(409));
        
        HttpResponse res = CalloutClass.getInfoFromExternalService();
        System.assert(res.getHeader('Content-Type') == 'application/json');
        System.assertEquals(res.getBody(), Constants.RESPONSE_409);
        System.assertEquals(409, res.getStatusCode());
    }
    
    @isTest static void testCallout403() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(403));
        
        HttpResponse res = CalloutClass.getInfoFromExternalService();
        System.assert(res.getHeader('Content-Type') == 'application/json');
        System.assertEquals(res.getBody(), Constants.RESPONSE_403);
        System.assertEquals(403, res.getStatusCode());
    }
    
    @isTest static void testCallout202() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(202));
        
        HttpResponse res = CalloutClass.getInfoFromExternalService();
        System.assert(res.getHeader('Content-Type') == 'application/json');
        System.assertEquals(202, res.getStatusCode());
        System.assertEquals(res.getBody(), Constants.RESPONSE_202);
    }
}