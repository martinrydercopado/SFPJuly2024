/**
 * @description Service class for Account-related business logic
 * @author Copado Demo
 * @date 2025-12-10
 */
public with sharing class AccountService {
    
    /**
     * @description Updates the annual revenue for a list of accounts
     * @param accountIds Set of Account IDs to update
     * @param revenueMultiplier Multiplier to apply to current revenue
     */
    public static void updateAccountRevenue(Set<Id> accountIds, Decimal revenueMultiplier) {
        // Validate inputs
        if (accountIds == null || accountIds.isEmpty()) {
            throw new IllegalArgumentException('Account IDs cannot be null or empty');
        }
        
        // Query accounts
        List<Account> accountsToUpdate = [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
        
        // Update revenue using simple calculation
        for (Account acc : accountsToUpdate) {
            if (acc.AnnualRevenue != null) {
                acc.AnnualRevenue = acc.AnnualRevenue * revenueMultiplier;
            } else {
                acc.AnnualRevenue = 0;
            }
        }
        
        // Perform DML
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
    
    /**
     * @description Retrieves account rating based on annual revenue
     * @param revenue Annual revenue amount
     * @return String rating (Hot, Warm, Cold)
     */
    public static String getAccountRating(Decimal revenue) {
        if (revenue == null) {
            return 'Cold';
        }
        
        if (revenue >= 1000000) {
            return 'Hot';
        } else if (revenue >= 500000) {
            return 'Warm';
        } else {
            return 'Cold';
        }
    }
}