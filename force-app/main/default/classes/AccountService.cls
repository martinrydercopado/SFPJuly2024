/**
 * @description Service class for Account-related business logic
 * @author Copado Demo
 * @date 2025-12-10
 */
public with sharing class AccountService {
    
    private static final Decimal DEFAULT_REVENUE = 0;
    private static final Decimal HOT_THRESHOLD = 1000000;
    private static final Decimal WARM_THRESHOLD = 500000;
    
    /**
     * @description Updates the annual revenue for a list of accounts
     * @param accountIds Set of Account IDs to update
     * @param revenueMultiplier Multiplier to apply to current revenue
     * @throws IllegalArgumentException if accountIds is null or empty
     * @example
     * Set<Id> accountIds = new Set<Id>{acc1.Id, acc2.Id};
     * AccountService.updateAccountRevenue(accountIds, 1.5);
     */
    public static void updateAccountRevenue(Set<Id> accountIds, Decimal revenueMultiplier) {
        validateInputs(accountIds);
        
        List<Account> accountsToUpdate = queryAccounts(accountIds);
        List<Account> processedAccounts = calculateRevenueUpdates(accountsToUpdate, revenueMultiplier);
        
        if (!processedAccounts.isEmpty()) {
            update processedAccounts;
        }
    }
    
    /**
     * @description Retrieves account rating based on annual revenue
     * @param revenue Annual revenue amount
     * @return String rating (Hot, Warm, Cold)
     * @example
     * String rating = AccountService.getAccountRating(1500000); // Returns 'Hot'
     */
    public static String getAccountRating(Decimal revenue) {
        if (revenue == null) {
            return 'Cold';
        }
        
        if (revenue >= HOT_THRESHOLD) {
            return 'Hot';
        } else if (revenue >= WARM_THRESHOLD) {
            return 'Warm';
        }
        return 'Cold';
    }
    
    /**
     * @description Validates input parameters for revenue update
     * @param accountIds Set of Account IDs to validate
     * @throws IllegalArgumentException if accountIds is null or empty
     */
    private static void validateInputs(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            throw new IllegalArgumentException('Account IDs cannot be null or empty');
        }
    }
    
    /**
     * @description Queries accounts by IDs with security enforced
     * @param accountIds Set of Account IDs to query
     * @return List of Account records with Id and AnnualRevenue fields
     */
    private static List<Account> queryAccounts(Set<Id> accountIds) {
        return [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
    }
    
    /**
     * @description Calculates revenue updates for accounts
     * @param accounts List of accounts to process
     * @param multiplier Multiplier to apply to revenue
     * @return List of accounts with updated revenue values
     */
    private static List<Account> calculateRevenueUpdates(List<Account> accounts, Decimal multiplier) {
        for (Account acc : accounts) {
            acc.AnnualRevenue = calculateNewRevenue(acc.AnnualRevenue, multiplier);
        }
        return accounts;
    }
    
    /**
     * @description Calculates new revenue value
     * @param currentRevenue Current revenue amount
     * @param multiplier Multiplier to apply
     * @return Calculated revenue value
     */
    private static Decimal calculateNewRevenue(Decimal currentRevenue, Decimal multiplier) {
        return (currentRevenue != null) ? currentRevenue * multiplier : DEFAULT_REVENUE;
    }
}