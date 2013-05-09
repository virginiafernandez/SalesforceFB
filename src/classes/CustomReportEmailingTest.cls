/**
 * This class tests the custom report emailing.
 *
 * @author  Virginia Fernández
 * @date    24/04/2013
 */
@isTest
private class CustomReportEmailingTest {

    private static void successSettings() {
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        settings.Client_Key__c = OauthHttpCalloutMock.CLIENT_ID;
        settings.Client_Secret__c = OauthHttpCalloutMock.CLIENT_SECRET;
        settings.Refresh_Token__c = OauthHttpCalloutMock.RESPONSE_REFRESH_TOKEN;
        insert settings;
    }
    
    private static void errorSettings() {
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        settings.Client_Key__c = '1234';
        settings.Client_Secret__c = '1234';
        settings.Refresh_Token__c = '123456';
        insert settings;
    }
    
    
    static testMethod void schedulerSuccessTest() {
        successSettings(); 
        
        Test.startTest();
        
        System.schedule('Test Custom Report Emailing', '0 0 * * * ?', new CustomReportEmailingScheduler());
        
        Test.stopTest();
    }
    
    static testMethod void schedulerErrorTest() {
        errorSettings();
        
        Test.startTest();
        
        System.schedule('Test Custom Report Emailing', '0 0 * * * ?', new CustomReportEmailingScheduler());
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void restTest() {
    	
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        settings.Users__c = Userinfo.getUserId();
        update settings; 
        
        delete Custom_Reports__c.getAll().values();  
        
        Report report = [select Id, Name from Report limit 1]; 
        
        Custom_Reports__c customReport = new Custom_Reports__c();
        customReport.Name = report.Id;
        customReport.Report_Name__c = report.Name;
        customReport.User_Filter__c = true;
        insert customReport;
             
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/SendCustomReport/';
        
        Test.startTest();
        
        CustomReportEmailingAPI.sendEmail();
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void allUsersTest() {
        
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        settings.Users__c = 'all';
        update settings; 
        
        delete Custom_Reports__c.getAll().values();  
        
        Report report = [select Id, Name from Report limit 1]; 
        
        Custom_Reports__c customReport = new Custom_Reports__c();
        customReport.Name = report.Id;
        customReport.Report_Name__c = report.Name;
        customReport.User_Filter__c = true;
        insert customReport;
             
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/SendCustomReport/';
        
        Test.startTest();
        
        CustomReportEmailingAPI.sendEmail();
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void reportTest() {
        
        Report report = [select Id, Name from Report limit 1]; 
        
        Test.startTest();
        
        Apexpages.currentPage().getParameters().put('reportId', report.Id);
        Apexpages.currentPage().getParameters().put('userId', UserInfo.getUserId());
        
        CustomReportEmailingController reportController = new CustomReportEmailingController();
        reportController.getReport();
        String reportHtml = reportController.getReportHtml();
        System.assert(reportHtml.startsWith('<table>'));
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void reportNoFilterTest() {
        
        Report report = [select Id, Name from Report limit 1]; 
        
        Test.startTest();
        
        Apexpages.currentPage().getParameters().put('reportId', report.Id);
        
        CustomReportEmailingController reportController = new CustomReportEmailingController();
        reportController.getReport();
        String reportHtml = reportController.getReportHtml();
        System.assert(reportHtml.startsWith('<table>'));
        
        Test.stopTest();
    }
}