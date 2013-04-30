global class FogBugzHttpCalloutMock implements HttpCalloutMock {
    
    private String responseBody;
    public static final String RESPONSE_TAGS = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="1">' +
                                                 '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind">'+
                                                 '<tags><tag><![CDATA[[0/20]]]></tag><tag><![CDATA[Test]]></tag><tag><![CDATA[CommCare]]></tag></case>'+
                                                 '</cases></response>';
    public static final String RESPONSE_UPDATE = '<?xml version="1.0" encoding="UTF-8"?><response>' +
                                                 '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind">'+
                                                 '</case></response>';
                                                 
    public static final String RESPONSE_SEARCH = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="1">' +
                                                 '<case ixBug="testFBId"><ixBug>testFBId</ixBug><sTitle>Title</sTitle><sArea>area</sArea><sPersonAssignedTo>salesforce</sPersonAssignedTo><sVersion>1</sVersion><ixPersonOpenedBy>salesforce</ixPersonOpenedBy><dtLastUpdated></dtLastUpdated>'+
                                                 '</case></cases></response>';
    
    public FogBugzHttpCalloutMock() {
    	this.responseBody = RESPONSE_UPDATE;
    }
    
    public FogBugzHttpCalloutMock(String responseBody) {
    	this.responseBody = responseBody;
    }
    
    global HTTPResponse respond(HTTPRequest req) {

    	HTTPResponse res = new HTTPResponse();
    	String reqBody = req.getBody();
    	
    	String[] parameters = reqBody.split('&');
        Map<String, String> params = new Map<String, String>();

        for (String param : parameters) {
            String[] p = param.split('=');
            params.put(p[0],p[1]);
        }
    	
    	if (params.get('cmd') == 'search') {
    		
    		if (params.containsKey('q')) {
    			
    			if (params.get('cols') == 'tags') {
    				
    				res.setBody(RESPONSE_TAGS);
    			}
    			else {
                    res.setBody(RESPONSE_SEARCH);
    			}
    			
    		}
    		else {
                res.setBody(RESPONSE_LIST_CASES);
    		}
    		
    	}        
    	else if (params.get('cmd') == 'setCurrentFilter') {
    		res.setBody(RESPONSE_FILTER);
    	}
    	else if ((params.get('cmd') == 'new') || (params.get('cmd') == 'resolve') || (params.get('cmd') == 'close') || (params.get('cmd') == 'edit')) {
    		res.setBody(RESPONSE_UPDATE);
    	}
    	else if (params.get('cmd') == 'viewPerson') {
    		res.setBody(RESPONSE_VIEW_PERSON);
    	}
        
        return res;
    }
}