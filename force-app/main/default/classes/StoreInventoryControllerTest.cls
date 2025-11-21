@isTest
private class StoreInventoryControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data - using 35 for Medium stock status (between 10-50 thresholds)
        List<Product2> products = TestDataFactory.createProducts(2);
        List<Store__c> stores = TestDataFactory.createStores(5);
        
        List<Id> storeIds = new List<Id>();
        for (Store__c store : stores) {
            storeIds.add(store.Id);
        }
        
        TestDataFactory.createStoreInventory(products[0].Id, storeIds, 35);
    }
    
    @isTest
    static void testGetProductInventory() {
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        List<Store_Inventory__c> inventories = StoreInventoryController.getProductInventory(product.Id);
        Test.stopTest();
        
        System.assertEquals(5, inventories.size(), 'Should return 5 inventory records (one per store)');
        System.assertNotEquals(null, inventories[0].Product__r.Name, 'Product name should be populated');
    }
    
    @isTest
    static void testGetProductInventoryBlankId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            StoreInventoryController.getProductInventory('');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should have thrown AuraHandledException for blank product ID');
    }
    
    @isTest
    static void testGetStoresByProduct() {
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        List<StoreInventoryController.StoreInventoryWrapper> wrappers = 
            StoreInventoryController.getStoresByProduct(product.Id, 100);
        Test.stopTest();
        
        System.assertEquals(5, wrappers.size(), 'Should return 5 store wrappers');
        System.assertNotEquals(null, wrappers[0].storeName, 'Store name should be populated');
        System.assertEquals(35, wrappers[0].quantity, 'Quantity should be 35');
        System.assertEquals(true, wrappers[0].inStock, 'Should be in stock');
        System.assertEquals('Medium', wrappers[0].stockStatus, 'Stock status should be Medium');
    }
    
    @isTest
    static void testGetStoresByProductBlankId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            StoreInventoryController.getStoresByProduct('', 100);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should have thrown AuraHandledException for blank product ID');
    }
    
    @isTest
    static void testUpdateStockCount() {
        Store_Inventory__c inventory = [SELECT Id, Quantity__c FROM Store_Inventory__c LIMIT 1];
        
        Test.startTest();
        StoreInventoryController.updateStockCount(inventory.Id, 100);
        Test.stopTest();
        
        Store_Inventory__c updatedInventory = [SELECT Quantity__c FROM Store_Inventory__c WHERE Id = :inventory.Id];
        System.assertEquals(100, updatedInventory.Quantity__c, 'Quantity should be updated to 100');
    }
    
    @isTest
    static void testUpdateStockCountBlankId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            StoreInventoryController.updateStockCount('', 50);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should have thrown AuraHandledException for blank inventory ID');
    }
    
    @isTest
    static void testUpdateStockCountNegativeQuantity() {
        Store_Inventory__c inventory = [SELECT Id FROM Store_Inventory__c LIMIT 1];
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            StoreInventoryController.updateStockCount(inventory.Id, -10);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should have thrown AuraHandledException for negative quantity');
    }
}