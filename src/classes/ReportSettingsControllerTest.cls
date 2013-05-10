/**
 * This class tests the ReportSettingsController class
 *
 * @author  Virginia Fernández
 * @date    23/04/2013
 */
@isTest(SeeAllData=true)
private class ReportSettingsControllerTest {

    private static void createReportSettings() {
    
    	Reports_Settings__c report = Reports_Settings__c.getOrgDefaults();
        report.Custom_Report_Emailing_Scheduler__c = null;
        report.Users__c = null;
        report.Client_Key__c = OauthHttpCalloutMock.CLIENT_ID;
        report.Client_Secret__c = OauthHttpCalloutMock.CLIENT_SECRET;
        report.Redirect_Url__c = OauthHttpCalloutMock.REDIRECT_URL;
        report.Refresh_Token__c = null;
        report.Scheduling_Time__c = null;        
        update report;
        
        delete Custom_Reports__c.getAll().values();
    }
    
    static testMethod void initializationTest() {        
        createReportSettings();
            
        Test.startTest();
        
        ReportSettingsController settings = new ReportSettingsController();
        
        List<SelectOption> hours = settings.getHours();
        System.assertEquals(hours.size(), 24);
        for (Integer i = 0; i < 24;i++) {
        	System.assertEquals(hours.get(i).getValue(), String.valueOf(i));
        	System.assertEquals(hours.get(i).getLabel(), String.valueOf(i));
        }
        
        PageReference pr = settings.saveSettings();
        System.assertEquals(settings.getStatus(), 'Start');
        System.assert(settings.getSelectedUsers().isEmpty());
        System.assert(!settings.getReports().isEmpty());
        System.assert(!settings.getUsers().isEmpty());
        System.assertEquals(settings.getNextFireTime(), '');
        System.assertEquals(null, settings.getCronState());
        System.assert(pr == null);
        
        Test.stopTest();
    }
    
    static testMethod void initializationWithDataTest() {        
        createReportSettings();
        
        User user = [select Id from User LIMIT 1];
        
        Reports_Settings__c reportSetting = Reports_Settings__c.getOrgDefaults();
        reportSetting.Users__c = user.Id;
        reportSetting.Custom_Report_Emailing_Scheduler__c = '1234';        
        update reportSetting;
        
        Report report = [select Id, Name from Report LIMIT 1];
        
        Custom_Reports__c customReport = new Custom_Reports__c();
        customReport.Name = report.Id;
        customReport.Report_Name__c = report.Name;
        customReport.User_Filter__c = true;
        customReport.Day__c = 1;
        customReport.Hour__c = 0;
        insert customReport;
            
        Test.startTest();
        
        ReportSettingsController settings = new ReportSettingsController();
        System.assertEquals(settings.getStatus(), 'Start');
        System.assertEquals(settings.getSelectedUsers().size(), 1);
        System.assertEquals(settings.getSelectedUsers().get(0), user.Id);
        System.assert(!settings.getReports().isEmpty());
        System.assert(!settings.getUsers().isEmpty());
        System.assertEquals(settings.getReports().get(0).getDay(), 1);
        System.assertEquals(settings.getReports().get(0).getHour(), 0);
        System.assertEquals(settings.getReports().get(0).getSelected(), true);
        System.assertEquals(settings.getReports().get(0).getFiltered(), true);
        System.assertEquals(settings.getReports().get(0).getName(), report.Name);
        settings.save();
        
        Test.stopTest();
    }
    
    static testMethod void saveTest() {
    	createReportSettings();
            
        Test.startTest();
        
        ReportSettingsController settings = new ReportSettingsController();
        String selectedUser = settings.getUsers().get(0).getValue();
        settings.setSelectedUsers(new List<String>{selectedUser});
        ReportSettingsController.CustomReport report = settings.getReports().get(0);
        report.setSelected(true);
        report.setFiltered(true);      
        report.setDay(0);
        report.setHour(9);  
        settings.save();
        
        Reports_Settings__c reportSettings = Reports_Settings__c.getOrgDefaults();
        System.assertEquals(reportSettings.Users__c,  selectedUser+',');
        Map<String,Custom_Reports__c> customReports = Custom_Reports__c.getAll();
        System.assertEquals(customReports.size(), 1);
        System.assert(customReports.containsKey(report.getId()));
        Custom_Reports__c customReport = customReports.get(report.getId());
        System.assertEquals(customReport.User_Filter__c, true);
        System.assertEquals(customReport.Report_Name__c, report.getName());
        System.assertEquals(customReport.Hour__c, 9);
        System.assertEquals(customReport.Day__c, 0);
        
        Test.stopTest();
    }
    
    static testMethod void startSchedulerNoAllowTest() {
    	createReportSettings();
            
        Test.startTest();
        
        ReportSettingsController settings = new ReportSettingsController();
        PageReference pr = settings.start();
        System.assertEquals(settings.getErrorStart(), 'ERROR - To run the scheduler you need to allow the access');
        
        Test.stopTest();
    }
    
    static testMethod void initializerCodeTest() {
     	createReportSettings();
            
        Apexpages.currentPage().getParameters().put('code', OauthHttpCalloutMock.CODE);
        ReportSettingsController settings = new ReportSettingsController();
        PageReference pr = settings.saveSettings();
        Reports_Settings__c reportSettings = Reports_Settings__c.getOrgDefaults();
        System.assertEquals(reportSettings.Refresh_Token__c, OauthHttpCalloutMock.REFRESH_TOKEN);
        
        Apexpages.currentPage().getParameters().remove('code');
        settings = new ReportSettingsController();
        settings.SCHEDULER_NAME += ' Test';
        settings.start();
        System.assert(settings.getReadOnly());
        reportSettings = Reports_Settings__c.getOrgDefaults();
        CronTrigger cg = [select Id, State, NextFireTime from CronTrigger where Id =: reportSettings.Custom_Report_Emailing_Scheduler__c];
        System.assertEquals(cg.State, settings.getCronState());
        System.assertEquals(cg.NextFireTime.format(), settings.getNextFireTime());
        System.assertEquals(settings.getStatus(), 'Stop');
        
     }
     
     static testMethod void codeErrorTest() {
     	
     	Reports_Settings__c reportSettings = Reports_Settings__c.getOrgDefaults();
     	reportSettings.Custom_Report_Emailing_Scheduler__c = null;
        reportSettings.Users__c = null;
        reportSettings.Client_Key__c = '1234';
        reportSettings.Client_Secret__c = '1234';
        reportSettings.Redirect_Url__c = OauthHttpCalloutMock.REDIRECT_URL;
        reportSettings.Refresh_Token__c = null;
        reportSettings.Scheduling_Time__c = null;        
        update reportSettings;
        
        delete Custom_Reports__c.getAll().values();
        
        Test.startTest();
        
        Apexpages.currentPage().getParameters().put('code', '1234');
        ReportSettingsController settings = new ReportSettingsController();
        settings.saveSettings();
        reportSettings = Reports_Settings__c.getOrgDefaults();
        System.assertEquals(reportSettings.Refresh_Token__c, null);
        
        Test.stopTest();
     }
     
     static testMethod void allowAccessErrorTest() {
        Reports_Settings__c report = Reports_Settings__c.getOrgDefaults();
        report.Custom_Report_Emailing_Scheduler__c = null;
        report.Users__c = null;
        report.Client_Key__c = OauthHttpCalloutMock.CLIENT_ID;
        report.Client_Secret__c = OauthHttpCalloutMock.CLIENT_SECRET;
        report.Redirect_Url__c = null;
        report.Refresh_Token__c = null;
        report.Scheduling_Time__c = null;        
        update report;
        
        Test.startTest();
        
        ReportSettingsController settings = new ReportSettingsController();
        Pagereference pr = settings.allowAccess();
        System.assertEquals(settings.getErrorAllow(), 'ERROR: You have to fill in the custom setting information');
        System.assertEquals(pr, null);
        
        Test.stopTest();
     }
     
     static testMethod void allUsersTest() {
     	
     	Reports_Settings__c report = Reports_Settings__c.getOrgDefaults();
     	report.Custom_Report_Emailing_Scheduler__c = null;
     	update report;
     	
     	Test.startTest();
        
        ReportSettingsController settings = new ReportSettingsController();
        settings.setAllUsers(true);
        settings.save();
        
        report = Reports_Settings__c.getOrgDefaults();
        System.assertEquals(report.Users__c, 'all');
        
        settings = new ReportSettingsController();
        System.assertEquals(settings.getAllUsers(), true);
        
        Test.stopTest();
     }
          
    
}