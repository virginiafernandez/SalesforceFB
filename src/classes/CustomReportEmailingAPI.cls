@RestResource(urlMapping='/SendCustomReport/*')
global with sharing class CustomReportEmailingAPI {
    @HttpGet
    global static void sendEmail() {
        
        List<Messaging.Email> emails = new List<Messaging.Email>();
        Map<String, Custom_Reports__c> reportsMap = Custom_Reports__c.getAll();
        Iterator<String> reportsNames = reportsMap.keySet().iterator();
        
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        List<String> usersId = new List<String>();
        
        List<User> users = new List<User>();
        
        if ((settings.Users__c != null) && (!settings.Users__c.equals('all'))) {
            usersId = settings.Users__c.split(',');
            users = [Select Id, Email from User where id in :usersId];
        }
        else if ((settings.Users__c != null) && (settings.Users__c.equals('all'))) {
        	users = [Select Id, Email from User];
        }        
        
        if (!users.isEmpty()) {
        	
        	while (reportsNames.hasNext()) {
        		
        		String reportName = reportsNames.next();
                Custom_Reports__c report = reportsMap.get(reportName);
	            
		        for (User user: users) {
		            
		            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		            mail.setToAddresses(new String[]{user.Email});
		            mail.setSubject(report.Report_Name__c+' Report');
		            
		            String url = '/apex/CustomReportEmailing?reportId='+reportName;
		            if (report.User_Filter__c) {
		            	url += '&userId='+user.Id;
		            }
		            
		            Pagereference report_page = new Pagereference(url);
		            
		            if (Test.isRunningTest()) {
		            	mail.setHtmlBody('<table></table>');
		            }
		            else {
                        mail.setHtmlBody(report_page.getContent().toString());
		            }
		            
		            emails.add(mail);
		            
		        }
		       
	        }
        }
        
        if (!emails.isEmpty()) {
        	Messaging.sendEmail(emails , false);
        }
    }
}