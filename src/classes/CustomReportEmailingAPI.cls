/**
 * This class is the rest api class that sends the report by mail
 *
 * @author  Virginia Fernández
 * @date    22/04/2013
 */
@RestResource(urlMapping='/SendCustomReport/*')
global with sharing class CustomReportEmailingAPI {
	
	//Representation between day of the week and number saved in the setting
	public final static Map<String, Integer> MAP_DAYS = new Map<String, Integer>{'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6, 'Sun' => 7};  
	
    @HttpGet
    global static void sendEmail() {
        
        List<Messaging.Email> emails = new List<Messaging.Email>();
        Map<String, Custom_Reports__c> reportsMap = Custom_Reports__c.getAll();
        Iterator<String> reportsNames = reportsMap.keySet().iterator();
        
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        Integer interval = (settings.Scheduling_Interval__c != null) ? Integer.valueOf(settings.Scheduling_Interval__c) : 15;
        List<String> usersId = new List<String>();
        
        List<User> users = new List<User>();
        
        //We get the users to send the email to
        if ((settings.Users__c != null) && (!settings.Users__c.equals('all'))) {
            usersId = settings.Users__c.split(',');
            users = [Select Id, Email from User where id in :usersId];
        }
        else if ((settings.Users__c != null) && (settings.Users__c.equals('all'))) {
        	users = [Select Id, Email from User];
        }        
        
        if (!users.isEmpty()) {
        	
        	//For each report schedule to be sent we send it if the day and hour are correct
        	while (reportsNames.hasNext()) {
        		
        		String reportName = reportsNames.next();
                Custom_Reports__c report = reportsMap.get(reportName);
	            
	            Datetime now = Datetime.now();
	            String dayOfWeek = now.format('E');
	            Integer hour = Integer.valueOf(now.format('h'));
	            Integer minute = Integer.valueOf(now.format('m'));
	            
	            //We see if the scheduled hour of the report is in a interval of the current hour 
	            if (((Integer.valueOf(report.Day__c) == 0) || 
	               (Integer.valueOf(report.Day__c) == MAP_DAYS.get(dayOfWeek))) &&
	               (((Integer.valueOf(report.Hour__c) == hour) && (minute <= interval)) || 
	               ((Integer.valueOf(report.Hour__c) == hour + 1) && 
	               (minute >= 60 - interval)))) {
	            
			        for (User user: users) {
			            
			            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			            mail.setToAddresses(new String[]{user.Email});
			            mail.setSubject(report.Report_Name__c+' Report');
			            
			            String url = '/apex/CustomReportEmailing?reportId='+reportName;
			            if (report.User_Filter__c) {
			            	url += '&userId='+user.Id;
			            }
			            
			            //We get the report content
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
        }
        
        if (!emails.isEmpty()) {
        	Messaging.sendEmail(emails , false);
        }
    }
}