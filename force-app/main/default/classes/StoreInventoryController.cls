public with sharing class StoreInventoryController {
    
    // Get product inventory data for a specific product
    @AuraEnabled(cacheable=true)
    public static List<Store_Inventory__c> getProductInventory(String productId) {
        if (String.isBlank(productId)) {
            throw new AuraHandledException('Product ID cannot be blank');
        }
        
        try {
            return [
                SELECT Id, Product__c, Product__r.Name, Product__r.ProductCode, 
                       Store__c, Store__r.Name, Quantity__c, Last_Updated__c
                FROM Store_Inventory__c
                WHERE Product__c = :productId
                ORDER BY Store__r.Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving product inventory: ' + e.getMessage());
        }
    }
    
    // Get stores by product with optional distance filtering
    @AuraEnabled(cacheable=true)
    public static List<StoreInventoryWrapper> getStoresByProduct(String productId, Decimal maxDistance) {
        if (String.isBlank(productId)) {
            throw new AuraHandledException('Product ID cannot be blank');
        }
        
        try {
            List<Store_Inventory__c> inventories = [
                SELECT Id, Store__c, Store__r.Name, Store__r.Address__c, 
                       Store__r.City__c, Store__r.State__c, Store__r.Zip__c,
                       Store__r.Phone__c, Store__r.Latitude__c, Store__r.Longitude__c,
                       Quantity__c, Last_Updated__c
                FROM Store_Inventory__c
                WHERE Product__c = :productId
                ORDER BY Store__r.Name ASC
            ];
            
            List<StoreInventoryWrapper> wrappers = new List<StoreInventoryWrapper>();
            for (Store_Inventory__c inv : inventories) {
                StoreInventoryWrapper wrapper = new StoreInventoryWrapper();
                wrapper.inventoryId = inv.Id;
                wrapper.storeName = inv.Store__r.Name;
                wrapper.address = inv.Store__r.Address__c;
                wrapper.city = inv.Store__r.City__c;
                wrapper.state = inv.Store__r.State__c;
                wrapper.zip = inv.Store__r.Zip__c;
                wrapper.phone = inv.Store__r.Phone__c;
                wrapper.latitude = inv.Store__r.Latitude__c;
                wrapper.longitude = inv.Store__r.Longitude__c;
                wrapper.quantity = Integer.valueOf(inv.Quantity__c);
                wrapper.inStock = inv.Quantity__c > 0;
                wrapper.stockStatus = InventoryService.getStockStatus(Integer.valueOf(inv.Quantity__c));
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving stores: ' + e.getMessage());
        }
    }
    
    // Update stock count for a store inventory record
    @AuraEnabled
    public static void updateStockCount(String storeInventoryId, Integer quantity) {
        if (String.isBlank(storeInventoryId)) {
            throw new AuraHandledException('Store Inventory ID cannot be blank');
        }
        
        if (quantity < 0) {
            throw new AuraHandledException('Quantity cannot be negative');
        }
        
        try {
            InventoryService.updateInventory(storeInventoryId, quantity);
        } catch (Exception e) {
            throw new AuraHandledException('Error updating stock count: ' + e.getMessage());
        }
    }
    
    // Wrapper class for store inventory data
    public class StoreInventoryWrapper {
        @AuraEnabled public String inventoryId { get; set; }
        @AuraEnabled public String storeName { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zip { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public Integer quantity { get; set; }
        @AuraEnabled public Boolean inStock { get; set; }
        @AuraEnabled public String stockStatus { get; set; }
    }
}