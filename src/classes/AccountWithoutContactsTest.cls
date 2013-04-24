/**
 * This class tests the scheduler for AccountsWithoutContacts report by user.
 *
 * @author  Virginia Fernández
 * @date    24/04/2013
 */
@isTest
private class AccountWithoutContactsTest {

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
        
        System.schedule('Test Account Without Contacts by User Report', '0 0 * * * ?', new AccountsWithoutContactsScheduler());
        
        Test.stopTest();
    }
    
    static testMethod void schedulerErrorTest() {
        errorSettings();
        
        Test.startTest();
        
        System.schedule('Test Account Without Contacts by User Report', '0 0 * * * ?', new AccountsWithoutContactsScheduler());
        
        Test.stopTest();
    }
    
    static testMethod void restTest() {
    	Country__c country = new Country__c();
    	country.Name = 'Test';
    	insert country;
    	
    	Account account = new Account();
    	account.Name = 'Test';
    	account.Country__c = country.Id;
    	insert account;
    	
    	System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/SendReport/';
        
        Test.startTest();
        
        AccountsWithoutContactsController.sendEmail();
        
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void reportTest() {
        
        Reports_Settings__c settings = Reports_Settings__c.getOrgDefaults();
        settings.Report_Id__c = '00Og0000000JP2f';
        update settings;
        
        Test.startTest();
        
        Apexpages.currentPage().getParameters().put('userId', Userinfo.getUserId());
        AccountReportController reportController = new AccountReportController();
        reportController.getReport();
        String reportHtml = reportController.getReportHtml();
        System.assert(reportHtml.startsWith('<table>'));
        
        Test.stopTest();
    }
}