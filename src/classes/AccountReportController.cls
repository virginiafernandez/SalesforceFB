public with sharing class AccountReportController {

    private String reportHtml;
    
    public void getReport() {
    	
    	Map<String, String> params = Apexpages.currentPage().getParameters();
    	String userId = params.get('userId');
    	
    	if (userId.length() > 15) {
    		userId = userId.substring(0,15);
    	}
    	
    	Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
    	String report_id = settings.Report_Id__c;
    	
    	Pagereference report = new Pagereference('/'+report_id+'?pv0='+userId+'&export=1&enc=UTF-8&xf=xls');
    	reportHtml = report.getContent().toString();
    }
    
    public String getReportHtml() {
        return reportHtml;  
    }
}