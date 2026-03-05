@isTest
private class InventoryServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test products
        List<Product2> products = TestDataFactory.createProducts(5);
        
        // Create test stores
        List<Store__c> stores = TestDataFactory.createStores(3);
        
        // Create inventory with varying quantities
        List<Id> storeIds = new List<Id>();
        for (Store__c store : stores) {
            storeIds.add(store.Id);
        }
        
        // Product 0: High stock (100 units per store)
        TestDataFactory.createStoreInventory(products[0].Id, storeIds, 100);
        
        // Product 1: Low stock (5 units per store)
        TestDataFactory.createStoreInventory(products[1].Id, storeIds, 5);
        
        // Product 2: Medium stock (30 units per store)
        TestDataFactory.createStoreInventory(products[2].Id, storeIds, 30);
    }
    
    @isTest
    static void testGetStockLevel() {
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product 0' LIMIT 1];
        
        Test.startTest();
        Integer stockLevel = InventoryService.getStockLevel(product.Id);
        Test.stopTest();
        
        System.assertEquals(300, stockLevel, 'Stock level should be 300 (100 per store * 3 stores)');
    }
    
    @isTest
    static void testGetStockLevelNullProduct() {
        Test.startTest();
        Integer stockLevel = InventoryService.getStockLevel(null);
        Test.stopTest();
        
        System.assertEquals(0, stockLevel, 'Stock level should be 0 for null product');
    }
    
    @isTest
    static void testUpdateInventory() {
        Store_Inventory__c inventory = [SELECT Id, Quantity__c FROM Store_Inventory__c LIMIT 1];
        
        Test.startTest();
        InventoryService.updateInventory(inventory.Id, 75);
        Test.stopTest();
        
        Store_Inventory__c updatedInventory = [SELECT Quantity__c FROM Store_Inventory__c WHERE Id = :inventory.Id];
        System.assertEquals(75, updatedInventory.Quantity__c, 'Quantity should be updated to 75');
    }
    
    @isTest
    static void testUpdateInventoryInvalidParameters() {
        Store_Inventory__c inventory = [SELECT Id FROM Store_Inventory__c LIMIT 1];
        
        Test.startTest();
        try {
            InventoryService.updateInventory(inventory.Id, -10);
            System.assert(false, 'Should have thrown exception for negative quantity');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateInventoryNullId() {
        Test.startTest();
        try {
            InventoryService.updateInventory(null, 50);
            System.assert(false, 'Should have thrown exception for null ID');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBulkUpdateInventories() {
        List<Store_Inventory__c> inventories = [SELECT Id FROM Store_Inventory__c LIMIT 200];
        Map<Id, Integer> updateMap = new Map<Id, Integer>();
        
        for (Store_Inventory__c inv : inventories) {
            updateMap.put(inv.Id, 50);
        }
        
        Test.startTest();
        InventoryService.updateInventories(updateMap);
        Test.stopTest();
        
        List<Store_Inventory__c> updatedInventories = [SELECT Quantity__c FROM Store_Inventory__c WHERE Id IN :updateMap.keySet()];
        for (Store_Inventory__c inv : updatedInventories) {
            System.assertEquals(50, inv.Quantity__c, 'All inventories should be updated to 50');
        }
    }
    
    @isTest
    static void testBulkUpdateInventoriesEmpty() {
        Test.startTest();
        InventoryService.updateInventories(new Map<Id, Integer>());
        InventoryService.updateInventories(null);
        Test.stopTest();
        
        System.assert(true, 'Should handle empty/null maps gracefully');
    }
    
    @isTest
    static void testGetLowStockProducts() {
        Test.startTest();
        List<Store_Inventory__c> lowStockItems = InventoryService.getLowStockProducts();
        Test.stopTest();
        
        System.assert(lowStockItems.size() > 0, 'Should have low stock items');
        for (Store_Inventory__c inv : lowStockItems) {
            System.assert(inv.Quantity__c < 10, 'All items should have quantity less than 10');
        }
    }
    
    @isTest
    static void testCalculateRestockAmount() {
        Test.startTest();
        Integer restockAmount = InventoryService.calculateRestockAmount(25, 100);
        Test.stopTest();
        
        System.assertEquals(75, restockAmount, 'Restock amount should be 75 (100 - 25)');
    }
    
    @isTest
    static void testCalculateRestockAmountNoRestockNeeded() {
        Test.startTest();
        Integer restockAmount = InventoryService.calculateRestockAmount(100, 50);
        Test.stopTest();
        
        System.assertEquals(0, restockAmount, 'No restock needed when current stock exceeds target');
    }
    
    @isTest
    static void testCalculateRestockAmountNegativeValues() {
        Test.startTest();
        Integer restockAmount = InventoryService.calculateRestockAmount(-10, 100);
        Test.stopTest();
        
        System.assertEquals(0, restockAmount, 'Should return 0 for negative current stock');
    }
    
    @isTest
    static void testGetStockStatus() {
        Test.startTest();
        String lowStatus = InventoryService.getStockStatus(5);
        String mediumStatus = InventoryService.getStockStatus(25);
        String highStatus = InventoryService.getStockStatus(75);
        Test.stopTest();
        
        System.assertEquals('Low', lowStatus, 'Status should be Low for quantity < 10');
        System.assertEquals('Medium', mediumStatus, 'Status should be Medium for quantity between 10-50');
        System.assertEquals('High', highStatus, 'Status should be High for quantity > 50');
    }
}