public with sharing class InventoryService {

    // Default threshold for low stock
    private static final Integer LOW_STOCK_THRESHOLD = 10;
    private static final Integer MEDIUM_STOCK_THRESHOLD = 50;

    // NEW METHOD: LWC-compatible wrapper for stock level calculation
    @AuraEnabled(cacheable=true)
    public static Integer getStockLevelForProduct(Id productId) {
        return getStockLevel(productId);
    }

    // Get stock level for a product across all stores
    public static Integer getStockLevel(Id productId) {
        if (productId == null) {
            return 0;
        }

        List<Store_Inventory__c> inventories = [
            SELECT Quantity__c
            FROM Store_Inventory__c
            WHERE Product__c = :productId
        ];

        Integer totalStock = 0;
        for (Store_Inventory__c inv : inventories) {
            if (inv.Quantity__c != null) {
                totalStock += Integer.valueOf(inv.Quantity__c);
            }
        }

        return totalStock;
    }

    // Update inventory quantity
    public static void updateInventory(Id storeInventoryId, Integer newQuantity) {
        if (storeInventoryId == null || newQuantity < 0) {
            throw new IllegalArgumentException('Invalid inventory update parameters');
        }

        Store_Inventory__c inventory = [
            SELECT Id, Quantity__c
            FROM Store_Inventory__c
            WHERE Id = :storeInventoryId
            LIMIT 1
        ];

        inventory.Quantity__c = newQuantity;
        inventory.Last_Updated__c = System.now();

        update inventory;
    }

    // Bulk update inventories
    public static void updateInventories(Map<Id, Integer> inventoryQuantityMap) {
        if (inventoryQuantityMap == null || inventoryQuantityMap.isEmpty()) {
            return;
        }

        List<Store_Inventory__c> inventoriesToUpdate = [
            SELECT Id, Quantity__c
            FROM Store_Inventory__c
            WHERE Id IN :inventoryQuantityMap.keySet()
        ];

        for (Store_Inventory__c inv : inventoriesToUpdate) {
            Integer newQty = inventoryQuantityMap.get(inv.Id);
            if (newQty != null && newQty >= 0) {
                inv.Quantity__c = newQty;
                inv.Last_Updated__c = System.now();
            }
        }

        update inventoriesToUpdate;
    }

    // Get products with low stock
    public static List<Store_Inventory__c> getLowStockProducts() {
        return [
            SELECT Id, Product__c, Product__r.Name, Store__c, Store__r.Name, Quantity__c, Last_Updated__c
            FROM Store_Inventory__c
            WHERE Quantity__c < :LOW_STOCK_THRESHOLD
            ORDER BY Quantity__c ASC
        ];
    }

    // Calculate recommended restock amount
    public static Integer calculateRestockAmount(Integer currentStock, Integer targetStock) {
        if (currentStock < 0 || targetStock < 0) {
            return 0;
        }

        Integer restockAmount = targetStock - currentStock;
        return restockAmount > 0 ? restockAmount : 0;
    }

    // Get stock status (Low, Medium, High)
    public static String getStockStatus(Integer quantity) {
        if (quantity < LOW_STOCK_THRESHOLD) {
            return 'Low';
        } else if (quantity < MEDIUM_STOCK_THRESHOLD) {
            return 'Medium';
        } else {
            return 'High';
        }
    }
}