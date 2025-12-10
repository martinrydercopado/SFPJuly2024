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
                AnnualRevenue = 100000 + (i * 1000),
                Industry = (Math.mod(i, 2) == 0) ? 'Technology' : 'Finance'
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
        // Note: Actual revenue will vary based on industry bonus (1.1x for Technology)
        System.assertNotEquals(
            originalRevenue, 
            updatedAccounts[0].AnnualRevenue, 
            'Revenue should be updated'
        );
    }
    
    @IsTest
    static void testUpdateAccountRevenue_WithTechnologyBonus() {
        // Given
        Account techAccount = new Account(
            Name = 'Tech Company',
            AnnualRevenue = 1000000,
            Industry = 'Technology'
        );
        insert techAccount;
        Decimal expectedRevenue = 1000000 * 2.0 * 1.1; // multiplier * tech bonus
        
        // When
        Test.startTest();
        AccountService.updateAccountRevenue(new Set<Id>{techAccount.Id}, 2.0);
        Test.stopTest();
        
        // Then
        Account updatedAccount = [
            SELECT AnnualRevenue 
            FROM Account 
            WHERE Id = :techAccount.Id
        ];
        System.assertEquals(
            expectedRevenue, 
            updatedAccount.AnnualRevenue, 
            'Technology accounts should receive 1.1x bonus'
        );
    }
    
    @IsTest
    static void testUpdateAccountRevenue_WithoutTechnologyBonus() {
        // Given
        Account nonTechAccount = new Account(
            Name = 'Finance Company',
            AnnualRevenue = 1000000,
            Industry = 'Finance'
        );
        insert nonTechAccount;
        Decimal expectedRevenue = 1000000 * 2.0 * 1.0; // multiplier * standard multiplier
        
        // When
        Test.startTest();
        AccountService.updateAccountRevenue(new Set<Id>{nonTechAccount.Id}, 2.0);
        Test.stopTest();
        
        // Then
        Account updatedAccount = [
            SELECT AnnualRevenue 
            FROM Account 
            WHERE Id = :nonTechAccount.Id
        ];
        System.assertEquals(
            expectedRevenue, 
            updatedAccount.AnnualRevenue, 
            'Non-Technology accounts should not receive bonus'
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
        // Given - Changed default from 0 to 10000 in Version 2
        Account acc = new Account(Name = 'Test Null Revenue', AnnualRevenue = null, Industry = 'Retail');
        insert acc;
        
        // When
        Test.startTest();
        AccountService.updateAccountRevenue(new Set<Id>{acc.Id}, 1.5);
        Test.stopTest();
        
        // Then
        Account updatedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(10000, updatedAccount.AnnualRevenue, 'Null revenue should be set to 10000');
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
        // When - Changed threshold from 1M to 2M in Version 2
        String rating = AccountService.getAccountRating(2500000);
        
        // Then
        System.assertEquals('Hot', rating, 'Should return Hot for revenue >= 2M');
    }
    
    @IsTest
    static void testGetAccountRating_Warm() {
        // When - Changed threshold from 500K to 750K in Version 2
        String rating = AccountService.getAccountRating(1000000);
        
        // Then
        System.assertEquals('Warm', rating, 'Should return Warm for revenue >= 750K');
    }
    
    @IsTest
    static void testGetAccountRating_Cold() {
        // When
        String rating = AccountService.getAccountRating(500000);
        
        // Then
        System.assertEquals('Cold', rating, 'Should return Cold for revenue < 750K');
    }
    
    @IsTest
    static void testGetAccountRating_Null() {
        // When
        String rating = AccountService.getAccountRating(null);
        
        // Then
        System.assertEquals('Cold', rating, 'Should return Cold for null revenue');
    }
    
    @IsTest
    static void testGetAccountRating_BoundaryHot() {
        // When - Test exact threshold
        String rating = AccountService.getAccountRating(2000000);
        
        // Then
        System.assertEquals('Hot', rating, 'Should return Hot at exact 2M threshold');
    }
    
    @IsTest
    static void testGetAccountRating_BoundaryWarm() {
        // When - Test exact threshold
        String rating = AccountService.getAccountRating(750000);
        
        // Then
        System.assertEquals('Warm', rating, 'Should return Warm at exact 750K threshold');
    }
}