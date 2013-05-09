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
    private Integer schedulingTime;
    private String status = 'Start';
    private String cronState = null;
    private Datetime cronNextFireTime = null; 
    private String errorStart = null;
    private String errorAllow = null;
    private boolean allUsers = false;
    
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
    
    public Integer getSchedulingTime() {
    	return schedulingTime;
    }
    
    public void setSchedulingTime(Integer schedulingTime) {
    	this.schedulingTime = schedulingTime;
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
    
    public ReportSettingsController() {
    	
    	Map<String, String> params = Apexpages.currentPage().getParameters();
    	settings = Reports_Settings__c.getOrgDefaults();
    	
    	if (params.containsKey('code')) {
    		
    		String code = params.get('code');
    		this.getRefreshToken(code);
    	}
    	else {
    	    
	    	users = new List<SelectOption>();
	        
	        if (settings.Custom_Report_Emailing_Scheduler__c != null) {
	        	
	        	List<CronTrigger> ct = [select Id, State, NextFireTime from CronTrigger where id =: settings.Custom_Report_Emailing_Scheduler__c];
	        	
	        	if (ct.isEmpty()) {
	        		settings.Custom_Report_Emailing_Scheduler__c = null;
	        	} 
	        	else {
	        		this.status = 'Stop';
	        		cronState = ct.get(0).State;
	                cronNextFireTime = ct.get(0).NextFireTime;
	                
	        	}
	        	
	        }
	        
	        selectedUsers = new String[]{};
	        schedulingTime = Integer.valueOf(settings.Scheduling_Time__c);
	        
	        if ((settings.Users__c != null) && (!settings.Users__c.equals('all'))) {
	            selectedUsers = settings.Users__c.split(',');
	        }
	        else if ((settings.Users__c != null) && (settings.Users__c.equals('all'))) {
	        	this.allUsers = true;
	        }
	        
	        for (User user: [select FirstName, LastName, Id from User]) {
	        	
	        	String name = '';
	        	
	        	if (user.FirstName != null) {
	        		name = user.FirstName + ' '; 
	        	}
	        	
	            users.add(new SelectOption(user.Id, name+user.LastName));
	                       
	        }
	                
	        Map<String, Custom_Reports__c> selectedReports = Custom_Reports__c.getAll();
	        reports = new List<CustomReport>();
	        
	        for (Report report: [select Id, Name from Report]) {
	        	
	            CustomReport customReport = new CustomReport(report.Id, report.Name);
	            
	            if (selectedReports.containsKey(report.Id)) {
	            	customReport.setSelected(true);
	            	customReport.setFiltered(selectedReports.get(report.Id).User_Filter__c);
	            }
	            
	            reports.add(customReport);
	        }
    	}
        
    }
    
    public void save() {
    	
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
    	
    	if (!Custom_Reports__c.getAll().values().isEmpty()) {
    	   delete Custom_Reports__c.getAll().values();
    	}
    	
    	List<Custom_Reports__c> selectedReports = new List<Custom_Reports__c>();
    	
    	for (CustomReport report : reports) {
    		
    		if (report.getSelected()) {
    			Custom_Reports__c customReport = new Custom_Reports__c();
    			customReport.Name = report.getId();
    			customReport.Report_Name__c = report.getName();
    			customReport.User_Filter__c = report.getFiltered();
    			selectedReports.add(customReport);
    		}
    		
    	}
    	
    	insert selectedReports;
    }
    
    private void getRefreshToken(String code) {
    	
    	String client_secret = settings.Client_Secret__c;
        String client_key = settings.Client_Key__c;
        String redirect_uri = settings.Redirect_Url__c;
        String instance_url = redirect_uri.substring(0,redirect_uri.indexOf('/apex/'));
        
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
    	
    	if (this.status == 'Start') {
    		
    		if ((schedulingTime != null) && (schedulingTime > 0)) {
    			
		    	settings.Scheduling_Time__c = schedulingTime;
		    	    	
		    	if (settings.Refresh_Token__c == null) {
		    		
		    		errorStart = 'ERROR - To run the scheduler you need to allow the access';
		    		System.debug('ERROR - To run the scheduler you need to allow the access');    
		    		
		    	}
		    	else {    		
		    		
		    		settings.Custom_Report_Emailing_Scheduler__c = System.schedule(SCHEDULER_NAME, '0 0 '+schedulingTime+' * * ?', new CustomReportEmailingScheduler());
		    		update settings;
		    		List<CronTrigger> ct = [select Id, State, NextFireTime from CronTrigger where id =: settings.Custom_Report_Emailing_Scheduler__c];
            
		            if (ct.isEmpty()) {		                
		                settings.Custom_Report_Emailing_Scheduler__c = null;		                
		            } 
		            else {
		            	
		                this.status = 'Stop';
		                cronState = ct.get(0).State;
                        cronNextFireTime = ct.get(0).NextFireTime;
                        
		            }		    		
		    	}
    		}
		}
    	else if (settings.Custom_Report_Emailing_Scheduler__c != null) {
    		
    		System.abortJob(settings.Custom_Report_Emailing_Scheduler__c);
    		this.status = 'Start';
    		cronState = null;
    		cronNextFireTime = null;
    		settings.Custom_Report_Emailing_Scheduler__c = null;
    		
    	}
    	
    	return null;
    }
    
    public class CustomReport {
    	
    	private String name;
    	private String id;
    	private boolean selected;
    	private boolean filtered;
    	
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
        
        public CustomReport(String id, String name) {
        	this.id = id;
        	this.name = name;
        	this.filtered = false;
        	this.selected = false;
        }
    }
}