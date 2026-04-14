/**
 * @description Test class for AccountService
 * @author Copado Demo
 * @date 2025-12-10
 */
@IsTest
private class AccountServiceTest {
    
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 200; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                AnnualRevenue = 100000 + (i * 1000)
            ));
        }
        
        insert testAccounts;
    }
    
    @IsTest
    static void testUpdateAccountRevenue_Success() {
        // Given
        List<Account> accounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 5];
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        Decimal originalRevenue = accounts[0].AnnualRevenue;
        Decimal multiplier = 1.5;
        
        // When
        Test.startTest();
        AccountService.updateAccountRevenue(accountIds, multiplier);
        Test.stopTest();
        
        // Then
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(5, updatedAccounts.size(), 'Should update 5 accounts');
        System.assertEquals(
            originalRevenue * multiplier, 
            updatedAccounts[0].AnnualRevenue, 
            'Revenue should be multiplied correctly'
        );
    }
    
    @IsTest
    static void testUpdateAccountRevenue_BulkOperation() {
        // Given
        List<Account> accounts = [SELECT Id FROM Account];
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        
        // When
        Test.startTest();
        AccountService.updateAccountRevenue(accountIds, 2.0);
        Test.stopTest();
        
        // Then
        List<Account> updatedAccounts = [SELECT Id FROM Account];
        System.assertEquals(200, updatedAccounts.size(), 'Should handle bulk operations');
    }
    
    @IsTest
    static void testUpdateAccountRevenue_NullRevenue() {
        // Given
        Account acc = new Account(Name = 'Test Null Revenue', AnnualRevenue = null);
        insert acc;
        
        // When
        Test.startTest();
        AccountService.updateAccountRevenue(new Set<Id>{acc.Id}, 1.5);
        Test.stopTest();
        
        // Then
        Account updatedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, updatedAccount.AnnualRevenue, 'Null revenue should be set to 0');
    }
    
    @IsTest
    static void testUpdateAccountRevenue_InvalidInput() {
        // When/Then
        try {
            Test.startTest();
            AccountService.updateAccountRevenue(null, 1.5);
            Test.stopTest();
            System.assert(false, 'Should throw exception for null input');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('cannot be null'), 'Should throw proper exception');
        }
    }
    
    @IsTest
    static void testGetAccountRating_Hot() {
        // When
        String rating = AccountService.getAccountRating(1500000);
        
        // Then
        System.assertEquals('Hot', rating, 'Should return Hot for revenue >= 1M');
    }
    
    @IsTest
    static void testGetAccountRating_Warm() {
        // When
        String rating = AccountService.getAccountRating(750000);
        
        // Then
        System.assertEquals('Warm', rating, 'Should return Warm for revenue >= 500K');
    }
    
    @IsTest
    static void testGetAccountRating_Cold() {
        // When
        String rating = AccountService.getAccountRating(250000);
        
        // Then
        System.assertEquals('Cold', rating, 'Should return Cold for revenue < 500K');
    }
    
    @IsTest
    static void testGetAccountRating_Null() {
        // When
        String rating = AccountService.getAccountRating(null);
        
        // Then
        System.assertEquals('Cold', rating, 'Should return Cold for null revenue');
    }
}