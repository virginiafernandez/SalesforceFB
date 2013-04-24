/**
 * This batch job runs the accounts without contacts report filtered by users and sends an email to the user with the report.
 *
 * @author  Virginia Fernández
 * @date    18/04/2013
 */
global without sharing class AccountsWithoutContactsScheduler implements Schedulable {
    
    public AccountsWithoutContactsScheduler() {
        
    }
        
    global void execute(SchedulableContext bc) {
        sendEmail();
    }
    
    @future (callout=true)
    public static void sendEmail() {
        
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        String client_secret = settings.Client_Secret__c;
        String client_key = settings.Client_Key__c;
        String refresh_token = settings.Refresh_Token__c;
        if ((client_secret != null) && (client_key != null) && (refresh_token != null)) {
	        Url salesforceBaseUrl = System.Url.getSalesforceBaseUrl();
	        String url_protocol = salesforceBaseUrl.getProtocol();
	        String url_host = salesforceBaseUrl.getHost();
	        String instance_url = url_protocol+'://'+url_host;
	        
	        Httprequest req = new Httprequest();
	        req.setEndpoint(instance_url+'/services/oauth2/token');
	        req.setBody('grant_type=refresh_token&client_secret='+client_secret+'&client_id='+client_key+'&refresh_token='+refresh_token);
	        req.setMethod('POST');
	        
	        Http http = new Http();
	        HttpResponse res = null;
	        
	        if (Test.isRunningTest()) {
	        	OauthHttpCalloutMock mock = new OauthHttpCalloutMock();
	        	res = mock.respond(req);
	        } 
	        else {
	            res = http.send(req);
	        }
	        
	        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
	        String access_token = (String) params.get('access_token');
	        
	        req = new Httprequest();
	        req.setEndpoint(instance_url+'/services/apexrest/SendReport/');
	        req.setMethod('GET');
	        req.setHeader('Authorization', 'Bearer '+access_token);         
	        http = new Http();
	        
	        if (Test.isRunningTest()) {
	            OauthHttpCalloutMock mock = new OauthHttpCalloutMock();
	            res = mock.respond(req);
	        } 
	        else {
	            res = http.send(req);
	        }
        }
        
	}
    
}