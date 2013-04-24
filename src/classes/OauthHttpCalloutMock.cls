global class OauthHttpCalloutMock implements HTTPCalloutMock {
	
	public static final String RESPONSE_ERROR = '{"success":"false"}';
    public static final String RESPONSE_TYPE_CODE = '{"refresh_token":"1234"}';
    public static final String RESPONSE_REFRESH_TOKEN = '{"access_token":"123456"}';
    public static final String RESPONSE_OK = '{"success":"true"}';
    
    public static final String ACCESS_TOKEN = '123456';
    public static final String REFRESH_TOKEN = '1234';
    public static final String CODE = '123456';
    public static final String REDIRECT_URL = 'https://www.test.com/apex/ReportSettings';
    public static final String CLIENT_SECRET = 'test';
    public static final String CLIENT_ID = 'test';
    
    private String responseBody;
    
    public OauthHttpCalloutMock() {}

    global HTTPResponse respond(HTTPRequest request) {
    	
    	HTTPResponse res = new HTTPResponse();
    	if (request.getMethod() == 'GET') {
    		if (request.getEndpoint().endsWith('/services/apexrest/SendReport/')) {
                if (request.getHeader('Authorization') == 'Bearer 123456') {
                	res.setBody(RESPONSE_OK);
                	return res;
                }
    		}
    	}
    	else {
    		
    		String body = request.getBody();
    		String[] parameters = body.split('&');
    		Map<String, String> params = new Map<String, String>();
    		
    		for (String param : parameters) {
    			String[] p = param.split('=');
    			params.put(p[0],p[1]);
    		}
    		
            if (params.get('grant_type') == 'authorization_code') {
            	
            	if ((params.get('client_secret') == CLIENT_SECRET) &&
            	    (params.get('client_id') == CLIENT_ID) &&
            	    (params.get('code') == CODE) &&
            	    (params.get('redirect_uri') == REDIRECT_URL)) {
	            
	                res.setBody(RESPONSE_TYPE_CODE);
	                return res;
                }
            }
            else if (params.get('grant_type') == 'refresh_token') {
            	
            	if ((params.get('client_secret') == CLIENT_SECRET) &&
                    (params.get('client_id') == CLIENT_ID) &&
                    (params.get('REFRESH_TOKEN') == REFRESH_TOKEN)) {
                
                    res.setBody(RESPONSE_REFRESH_TOKEN);
                    return res;
                    	
                }
            	
            }
    	}
    	
        res.setBody(RESPONSE_ERROR);
        return res;
    }
}