public with sharing class CustomReportEmailingController {
    private String reportHtml;
    
    public void getReport() {
        
        Map<String, String> params = Apexpages.currentPage().getParameters();
        
        String report_url = '/'+params.get('reportId');
        
        if (params.containsKey('userId')) {
	        String userId = params.get('userId');
	        
	        if (userId.length() > 15) {
	            userId = userId.substring(0,15);
	        }
	        
	        report_url += '?pv0='+userId+'&';
        }
        
        if (!report_url.contains('?')) {
        	report_url += '?';
        }
        
        Pagereference report = new Pagereference(report_url+'export=1&enc=UTF-8&xf=xls');
        
        if (Test.isRunningTest()) {
            reportHtml = '<table></table>';	
        }
        else {
            reportHtml = report.getContent().toString();
        }
    }
    
    public String getReportHtml() {
        return reportHtml;  
    }
    
}