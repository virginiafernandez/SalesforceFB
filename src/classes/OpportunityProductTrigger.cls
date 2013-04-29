/**
 * Trigger for OpportunityProduct
 *
 * @author  Virginia Fernández
 * @date    04/12/2013
 */
public with sharing class OpportunityProductTrigger {
	
	private static final Set<String> PRODUCTS_AS_TAGS = new Set<String>{'CommCare', 
		                                                                'CommConnect', 
		                                                                'CommTrack'};
	
	// entry for Inserts
	public static void onUpdate(OpportunityLineItem[] newOppProduct, boolean isDelete) {
		Set<Id> oppIds = new Set<Id>();
		Set<Id> pbIds = new Set<Id>();
		Map<String, String> mapProds = new Map<String, String>();
		
		for (OpportunityLineItem oli : newOppProduct) {
			oppIds.add(oli.OpportunityId);
			pbIds.add(oli.PricebookEntryId);
			
			if (!mapProds.containsKey(oli.OpportunityId)) {
				mapProds.put(oli.OpportunityId, oli.PricebookEntryId);
			}
			else {
                mapProds.put(oli.OpportunityId, mapProds.get(oli.OpportunityId) + ',' + oli.PricebookEntryId);
			}
			
		}
		
		if (isDelete) {
			removeTags(oppIds, pbIds, mapProds);
		}
		else {
            setTags(oppIds, pbIds);
		}
		
		Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>();
		Set<Id> pricebookIds = new Set<Id>();
		
		List<Opportunity> opps = [select Id, Product_Text__c, 
                                         (select PricebookEntryId from OpportunityLineItems) 
                                  from Opportunity 
                                  where id in :oppIds];
                                  
		for (Opportunity opp : opps) {
            mapOpps.put(opp.Id, opp);
            
            for (OpportunityLineItem item : opp.OpportunityLineItems) {
            	pricebookIds.add(item.PricebookEntryId);
            }
                    		                        	
        }
		          
        Map<Id, String> productNames = new Map<Id, String>();      
         
        for (PricebookEntry pe: [select Id, Product2.Name, Product2Id from PricebookEntry where Id in :pricebookIds]) {
        	productNames.put(pe.Id, pe.Product2.Name);
        }       
        
        for (Opportunity opp : opps) {
        	opp.Product_Text__c = '';
        	
        	for (OpportunityLineItem item : opp.OpportunityLineItems) {
        		
        		if ((opp.Product_Text__c != '') && (!opp.Product_Text__c.endsWith('; '))) {
        			opp.Product_Text__c += '; ';
        		}
        		opp.Product_Text__c += productNames.get(item.PricebookEntryId);
        		
        	}
        }
        
        update opps;
    }
    
    private static Map<String, FogBugzCase> fetchOpportunities(Set<Id> ids) {
        
        Map<String, FogBugzCase> mapOpps = new Map<String, FogBugzCase>();
        
        for (Opportunity opp : [select Id,
                                    Name,
                                    Owner.Name,
                                    Owner.Email,
                                    Owner.Id,
                                    StageName,
                                    Amount,
                                    Fogbugz_Most_Recent_Note__c,
                                    Probability,
                                    Fogbugz_Probability__c,
                                    Fogbugz_Ticket_Number__c,
                                    Fogbugz_Assigned_To__c,
                                    Fogbugz_Opened_By__c,
                                    Fogbugz_Last_Updated_Date__c
                             from Opportunity
                             where Id in :ids]) {
                                
            mapOpps.put(opp.Id, FogBugzUtils.createFBCaseFromOpportunity(opp));
        }
                             
        return mapOpps;
    }
    
    private static Map<String, List<String>> getMappOppProducts(Set<Id> pricebookIds) {
    	Map<String, List<String>> mapOppProducts = new Map<String, List<String>>();
        
        for (PricebookEntry pbe: [select Id, Product2.Name, Product2Id, 
                                         (select OpportunityId from OpportunityLineItems) 
                                  from PricebookEntry 
                                  where Id in :pricebookIds and Product2.Name in : PRODUCTS_AS_TAGS]) {
            
            for (OpportunityLineItem oli : pbe.OpportunityLineItems) {
                 
                if (!mapOppProducts.containsKey(oli.OpportunityId)) {
                    mapOppProducts.put(oli.OpportunityId, new List<String>());
                }
                
                mapOppProducts.get(oli.OpportunityId).add(pbe.Product2.Name);
            }
        }
        
        return mapOppProducts;
    }
    
    private static Map<String, String> getMappProductNames(Set<Id> pricebookIds) {
        Map<String, String> mapProductNames = new Map<String, String>();
        
        for (PricebookEntry pbe: [select Id, Product2.Name, Product2Id 
                                  from PricebookEntry 
                                  where Id in :pricebookIds and Product2.Name in : PRODUCTS_AS_TAGS]) {
            
            mapProductNames.put(pbe.Id, pbe.Product2.Name);
        }
        
        return mapProductNames;
    }

    @future(callout=true)
    private static void setTags(Set<Id> opps, Set<Id> pricebookIds) {
    	
    	Map<String, FogBugzCase> mapOpps = fetchOpportunities(opps);
        Map<String, List<String>> mapOppProducts = getMappOppProducts(pricebookIds);
        Iterator<String> itOpps = mapOpps.keySet().iterator();
        
        while (itOpps.hasNext()) {
            
            String oppId = itOpps.next();
            FogBugzCase fbCase = mapOpps.get(oppId);
            List<String> products = mapOppProducts.get(oppId);
            String tags = '';
            
            if (products != null) {
	            for (String product: products) {
	                tags += product + ',';
	            }
            
	            FogBugzAPI fbAPI = new FogBugzAPI();
	            String fbCaseId = fbAPI.addProductTag(fbCase, tags);
            }
            
        }       
    }    
    
    @future(callout=true)
    private static void removeTags(Set<Id> opps, Set<Id> pricebookIds, Map<String, String> mapProds) {
        
        Map<String, FogBugzCase> mapOpps = fetchOpportunities(opps);
        Map<String, String> mapProductsNames = getMappProductNames(pricebookIds);
        Iterator<String> itOpps = mapOpps.keySet().iterator();
        
        while (itOpps.hasNext()) {
            String oppId = itOpps.next();
            
            FogBugzCase fbCase = mapOpps.get(oppId);
            List<String> prodsId = mapProds.get(oppId).split(',');
            
            Set<String> tags = new Set<String>();
            
            
            for (String productId: prodsId) {
            	if (mapProductsNames.get(productId) != null) {
            	   tags.add(mapProductsNames.get(productId));	
            	}
            }
            
            FogBugzAPI fbAPI = new FogBugzAPI();
            String fbCaseId = fbAPI.removeProductTags(fbCase, tags);
        }       
        
    }
    
}