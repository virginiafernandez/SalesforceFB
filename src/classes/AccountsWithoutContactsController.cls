@RestResource(urlMapping='/SendReport/*')
global with sharing class AccountsWithoutContactsController {
    @HttpGet
    global static void sendEmail() {
    	
        Set<Id> users = new Set<Id>();
    	for (Account account: [Select OwnerId, Id from Account where Id not in (select AccountId from Contact) ]) {
    		users.add(account.OwnerId);
    	}
    	
    	List<Messaging.Email> emails = new List<Messaging.Email>();
    	
    	for (User user: [Select Id, Email from User where id in :users]) {
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        mail.setToAddresses(new String[]{user.Email});
	        mail.setSubject('Accunts without Contacts Report');
	        
	        Pagereference report = new Pagereference('/apex/AccountsWithoutContacts?userId='+user.Id);
	        mail.setHtmlBody(report.getContent().toString());
	        emails.add(mail);
	        
    	}
    	
    	Messaging.sendEmail(emails , false);
    }
}