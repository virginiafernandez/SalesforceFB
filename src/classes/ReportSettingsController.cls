public with sharing class ReportSettingsController {
    
    private List<CustomReport> reports;
    private List<SelectOption> users;
    private String[] selectedUsers;
    private boolean save = false;
    private Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
    
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
    	if (params.containsKey('code')) {
    		String code = params.get('code');
    		this.getRefreshToken(code);
    	} 
    	
    	users = new List<SelectOption>();
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        selectedUsers = new String[]{};
        
        if (settings.Users__c != null) {
            selectedUsers = settings.Users__c.split(',');
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
    
    public void save() {
    	
    	Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
    	settings.Users__c = '';
    	
    	for (String user: selectedUsers) {
            settings.Users__c += user+',';
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
        Httpresponse res = http.send(req);
        
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        settings.Refresh_Token__c = (String) params.get('refresh_token');
        save = true;
    }
    
    public Pagereference start() {
    	Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        String client_secret = settings.Client_Secret__c;
        String client_key = settings.Client_Key__c;
        String redirect_uri = settings.Redirect_Url__c;
        Url salesforceBaseUrl = System.Url.getSalesforceBaseUrl();
        String url_protocol = salesforceBaseUrl.getProtocol();
        String url_host = salesforceBaseUrl.getHost();
        String instance_url = url_protocol+'://'+url_host;
        
        Pagereference pr = new Pagereference(instance_url+'/services/oauth2/authorize?response_type=code&client_secret='+client_secret+'&client_id='+client_key+'&redirect_uri='+redirect_uri+'?type=oauth');
        pr.setRedirect(true);
        return pr;
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