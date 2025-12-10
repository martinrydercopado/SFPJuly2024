/**
 * @description Service class for Account-related business logic
 * @author Copado Demo
 * @date 2025-12-10
 */
public with sharing class AccountService {
    
    private static final Decimal DEFAULT_REVENUE = 10000;
    private static final Decimal HOT_THRESHOLD = 2000000;
    private static final Decimal WARM_THRESHOLD = 750000;
    private static final Decimal TECH_BONUS = 1.1;
    private static final Decimal STANDARD_MULTIPLIER = 1.0;
    private static final String TECH_INDUSTRY = 'Technology';
    
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
        
        List<Account> accountsToUpdate = queryAccountsWithIndustry(accountIds);
        List<Account> processedAccounts = calculateEnhancedRevenueUpdates(accountsToUpdate, revenueMultiplier);
        
        if (!processedAccounts.isEmpty()) {
            update processedAccounts;
        }
    }
    
    /**
     * @description Retrieves account rating based on annual revenue
     * @param revenue Annual revenue amount
     * @return String rating (Hot, Warm, Cold)
     * @example
     * String rating = AccountService.getAccountRating(2500000); // Returns 'Hot'
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
     * @description Queries accounts by IDs with industry field and security enforced
     * @param accountIds Set of Account IDs to query
     * @return List of Account records with Id, AnnualRevenue, and Industry fields
     */
    private static List<Account> queryAccountsWithIndustry(Set<Id> accountIds) {
        return [
            SELECT Id, AnnualRevenue, Industry
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
    }
    
    /**
     * @description Calculates enhanced revenue updates for accounts with industry bonus
     * @param accounts List of accounts to process
     * @param multiplier Multiplier to apply to revenue
     * @return List of accounts with updated revenue values
     */
    private static List<Account> calculateEnhancedRevenueUpdates(List<Account> accounts, Decimal multiplier) {
        for (Account acc : accounts) {
            Decimal industryBonus = getIndustryBonus(acc.Industry);
            acc.AnnualRevenue = calculateNewRevenue(acc.AnnualRevenue, multiplier, industryBonus);
        }
        return accounts;
    }
    
    /**
     * @description Determines industry bonus multiplier
     * @param industry Industry of the account
     * @return Bonus multiplier (1.1 for Technology, 1.0 otherwise)
     */
    private static Decimal getIndustryBonus(String industry) {
        return (industry == TECH_INDUSTRY) ? TECH_BONUS : STANDARD_MULTIPLIER;
    }
    
    /**
     * @description Calculates new revenue value with industry bonus
     * @param currentRevenue Current revenue amount
     * @param multiplier Multiplier to apply
     * @param bonus Industry bonus multiplier
     * @return Calculated revenue value
     */
    private static Decimal calculateNewRevenue(Decimal currentRevenue, Decimal multiplier, Decimal bonus) {
        return (currentRevenue != null) ? currentRevenue * multiplier * bonus : DEFAULT_REVENUE;
    }
}