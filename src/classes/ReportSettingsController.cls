/**
 * This class is the controller for the ReportSettings page.
 *
 * @author  Virginia Fernández
 * @date    22/04/2013
 */
public with sharing class ReportSettingsController {
	
	public String SCHEDULER_NAME = 'Custom Report Emailing';
    
    private List<CustomReport> reports;
    private List<SelectOption> users;
    private String[] selectedUsers;
    private boolean save = false;
    private Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
    private String status = 'Start';
    private String cronState = null;
    private Datetime cronNextFireTime = null; 
    private String errorStart = null;
    private String errorAllow = null;
    private boolean allUsers = false;
    private List<SelectOption> hours = new List<SelectOption>();
    private boolean readOnly = false; 
    
    public boolean getAllUsers() {
    	return allUsers;
    }
    
    public void setAllUsers(boolean allUsers) {
    	this.allUsers = allUsers;
    }
    
    public String getErrorStart() {
    	return errorStart;
    }
    
    public String getErrorAllow() {
        return errorAllow;
    }
    
    public List<CustomReport> getReports() {
    	return reports;
    }
    
    public List<SelectOption> getUsers() {
        return users;
    }
    
    public String[] getSelectedUsers() {
        return selectedUsers;
    }
    
    public void setSelectedUsers(String[] selectedUsers) {
        this.selectedUsers = selectedUsers;
    }
    
    public String getStatus() {
    	return this.status;
    }
    
    public String getCronState() {
        return cronState;
    }
    
    public String getNextFireTime() {
    	if (cronNextFireTime != null) {
            return cronNextFireTime.format();
    	}
    	else {
    		return '';
    	}
    }
    
    public Pagereference saveSettings() {
    	
    	if (save) {
    		
	    	update settings;
    		
    		Pagereference pr = new Pagereference('/apex/ReportSettings');
    		pr.setRedirect(true);
    		return pr;
    	}
    	
    	return null;
    }
    
    public List<SelectOption> getHours() {
    	return hours;
    }
    
    public boolean getReadOnly() {
    	return readOnly;
    }
    
    public ReportSettingsController() {
    	
    	for (Integer i=0; i<24;i++) {
    		hours.add(new SelectOption(String.valueOf(i),String.valueOf(i)));
    	}
    	
    	Map<String, String> params = Apexpages.currentPage().getParameters();
    	settings = Reports_Settings__c.getOrgDefaults();
    	
    	if (params.containsKey('code')) {
    		
    		//We are in the allow acces step
    		String code = params.get('code');
    		this.getRefreshToken(code);
    	}
    	else {
    	    
	    	users = new List<SelectOption>();
	        
	        //If the scheduler is running
	        if (settings.Custom_Report_Emailing_Scheduler__c != null) {
	        	
	        	List<CronTrigger> ct = [select Id, State, NextFireTime from CronTrigger where id =: settings.Custom_Report_Emailing_Scheduler__c];
	           
	            //If the scheduler isn' running but there is a Custom_Report_Emailing_Scheduler saved	
	        	if (ct.isEmpty()) {
	        		settings.Custom_Report_Emailing_Scheduler__c = null;
	        	} 
	        	else {
	        		readOnly = true;
	        		this.status = 'Stop';
	        		cronState = ct.get(0).State;
	                cronNextFireTime = ct.get(0).NextFireTime;
	                
	        	}
	        	
	        }
	        
	        selectedUsers = new String[]{};
	        
	        //If there are users selected we get the list of selected users
	        if ((settings.Users__c != null) && (!settings.Users__c.equals('all'))) {
	            selectedUsers = settings.Users__c.split(',');
	        }
	        //If we should send to all users
	        else if ((settings.Users__c != null) && (settings.Users__c.equals('all'))) {
	        	this.allUsers = true;
	        }
	        
	        //We get the list of all current users to show in the view
	        for (User user: [select FirstName, LastName, Id from User]) {
	        	
	        	String name = '';
	        	
	        	if (user.FirstName != null) {
	        		name = user.FirstName + ' '; 
	        	}
	        	
	            users.add(new SelectOption(user.Id, name+user.LastName));
	                       
	        }
	                
	        Map<String, Custom_Reports__c> selectedReports = Custom_Reports__c.getAll();
	        reports = new List<CustomReport>();
	        
	        //We get the list of current reports
	        for (Report report: [select Id, Name from Report]) {
	        	
	            CustomReport customReport = new CustomReport(report.Id, report.Name);
	            
	            //If the report was selected by the user
	            if (selectedReports.containsKey(report.Id)) {
	            	
	            	Custom_Reports__c reportSetting = selectedReports.get(report.Id);
	            	customReport.setSelected(true);
	            	
	            	if (reportSetting.Day__c != null) {
                        customReport.setDay(Integer.valueOf(reportSetting.Day__c));
	            	}
	            	
	            	if (reportSetting.Hour__c != null) {
                        customReport.setHour(Integer.valueOf(reportSetting.Hour__c));
	            	}
	            	
	            	customReport.setFiltered(reportSetting.User_Filter__c);
	            	
	            }
	            
	            reports.add(customReport);
	            
	        }
    	}
        
    }
    
    public void save() {
    	//We only allow to save the settings if the scheduler isn't running
    	if (!readOnly) {
	    	
	    	//We save the users selected to send the email to
	    	if (allUsers) {
	    	   settings.Users__c = 'all';	
	    	}
	    	else {
		    	settings.Users__c = '';
		    	
		    	for (String user: selectedUsers) {
		            settings.Users__c += user+',';
		    	}
	    	}
	    	
	    	update settings;
	    	
	    	//We delete the current reports selected
	    	if (!Custom_Reports__c.getAll().values().isEmpty()) {
	    	   delete Custom_Reports__c.getAll().values();
	    	}
	    	
	    	List<Custom_Reports__c> selectedReports = new List<Custom_Reports__c>();
	    	
	    	//We add the new selected reports to be sent by email
	    	for (CustomReport report : reports) {
	    		
	    		if (report.getSelected()) {
	    			
	    			Custom_Reports__c customReport = new Custom_Reports__c();
	    			customReport.Name = report.getId();
	    			customReport.Report_Name__c = report.getName();
	    			customReport.User_Filter__c = report.getFiltered();
	    			customReport.Day__c = Integer.valueOf(report.getDay());
	    			customReport.Hour__c = Integer.valueOf(report.getHour());
	    			selectedReports.add(customReport);
	    		}
	    		
	    	}
	    	
	    	insert selectedReports;
    	}
    }
    
    private void getRefreshToken(String code) {
    	
    	String client_secret = settings.Client_Secret__c;
        String client_key = settings.Client_Key__c;
        String redirect_uri = settings.Redirect_Url__c;
        String instance_url = redirect_uri.substring(0,redirect_uri.indexOf('/apex/'));
        
        //We get and save the refresh_token to allow access to this org
        Httprequest req = new Httprequest();
        req.setEndpoint(instance_url+'/services/oauth2/token');
        req.setBody('grant_type=authorization_code&client_secret='+client_secret+'&client_id='+client_key+'&redirect_uri='+redirect_uri+'&code='+code);
        req.setMethod('POST');
        Http http = new Http();
        Httpresponse res = null;
        
        if (Test.isRunningTest()) {
        	OauthHttpCalloutMock mock = new OauthHttpCalloutMock();
        	res = mock.respond(req);
        }
        else {
        	res = http.send(req);
        }
        
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        settings.Refresh_Token__c = (String) params.get('refresh_token');
        save = true;
    }
    
    public PageReference allowAccess() {
    	
    	String client_secret = settings.Client_Secret__c;
        String client_key = settings.Client_Key__c;
        String redirect_uri = settings.Redirect_Url__c;
        
        //We only can allow access if the settings for the remote access is saved in the custom setting
        if ((client_secret != null) && (client_key != null) && (redirect_uri != null)) {
        	
	        Url salesforceBaseUrl = System.Url.getSalesforceBaseUrl();
	        String url_protocol = salesforceBaseUrl.getProtocol();
	        String url_host = salesforceBaseUrl.getHost();
	        String instance_url = url_protocol+'://'+url_host;
	        
	        Pagereference pr = new Pagereference(instance_url+'/services/oauth2/authorize?response_type=code&client_secret='+client_secret+'&client_id='+client_key+'&redirect_uri='+redirect_uri);
	        pr.setRedirect(true);
	        return pr;
        }
        
        errorAllow = 'ERROR: You have to fill in the custom setting information';
        return null;
    }
    
    public Pagereference start() {
    	
    	//If the scheduler isn't running
    	if (this.status == 'Start') {
		    	    	
                //We need the refresh token to have been saved in the setting to start the scheduler
		    	if (settings.Refresh_Token__c == null) {
		    		
		    		errorStart = 'ERROR - To run the scheduler you need to allow the access';
		    		System.debug('ERROR - To run the scheduler you need to allow the access');    
		    		
		    	}
		    	else {    		
		    	     
		    	    //We run the scheduler every hour	
		    		settings.Custom_Report_Emailing_Scheduler__c = System.schedule(SCHEDULER_NAME, '0 0 * * * ?', new CustomReportEmailingScheduler());
		    		update settings;
		    		List<CronTrigger> ct = [select Id, State, NextFireTime from CronTrigger where id =: settings.Custom_Report_Emailing_Scheduler__c];
            
		            if (ct.isEmpty()) {		                
		                settings.Custom_Report_Emailing_Scheduler__c = null;		                
		            } 
		            else {
		            	
		                this.status = 'Stop';
		                cronState = ct.get(0).State;
                        cronNextFireTime = ct.get(0).NextFireTime;
                        readOnly = true;
		            }		    		
		    	}
		}
		//If the scheduler is running
    	else if (settings.Custom_Report_Emailing_Scheduler__c != null) {
    		
    		//We stop the scheduler
    		System.abortJob(settings.Custom_Report_Emailing_Scheduler__c);
    		this.status = 'Start';
    		cronState = null;
    		cronNextFireTime = null;
    		settings.Custom_Report_Emailing_Scheduler__c = null;
    		readOnly = false;
    		
    	}
    	
    	return null;
    }
    
    //This class represents the Custom_Reports__c setting 
    public class CustomReport {
    	
    	private String name;
    	private String id;
    	private boolean selected;
    	private boolean filtered;
    	private integer day = 0;
    	private integer hour = 0;
    	
    	public String getName() {
    		return name;
    	}
    	
    	public String getId() {
    		return id;
    	}
    	
    	public boolean getSelected() {
    		return selected;
    	}
    	
    	public void setSelected(boolean selected) {
    		this.selected = selected;
    	}
    	
    	public boolean getFiltered() {
            return filtered;
        }
        
        public void setFiltered(boolean filtered) {
            this.filtered = filtered;
        }
        
        public Integer getDay() {
            return day;
        }
        
        public void setDay(Integer day) {
            this.day = day;
        }
        
        public Integer getHour() {
        	return hour;
        }
        
        public void setHour(Integer hour) {
            this.hour = hour;
        }
        
        public CustomReport(String id, String name) {
        	this.id = id;
        	this.name = name;
        	this.filtered = false;
        	this.selected = false;
        }
    }
}