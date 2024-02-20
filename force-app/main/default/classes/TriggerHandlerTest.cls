/**
 * Created by vncasolns on 2024-02-01.
 */
@IsTest
public with sharing class TriggerHandlerTest {

    @IsTest
    static void testAccounts() {
        setupAccountMockFeatures();

        List<Account> accounts = getAccounts();
        insert accounts;

        accounts = [SELECT Id, AccountNumber, Description FROM Account WHERE Id IN :accounts];
        for (Account account : accounts) {
            System.assertEquals('Account created', account.Description);
        }
        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId IN :accounts];
        System.assertEquals(3, contacts.size());

        for (Account account : accounts) {
            account.Type = 'Other';
        }
        update accounts;
        accounts = [SELECT Id, Industry FROM Account WHERE Id IN :accounts];
        for (Account account : accounts) {
            System.assertEquals('Other', account.Industry);
        }

        Test.startTest();
        delete accounts;
        Test.stopTest();

        contacts = [SELECT Id FROM Contact WHERE AccountId IN :accounts];
        System.assertEquals(0, contacts.size());
    }

    @IsTest
    static void testFeatureDoesNotExist() {
        List<TriggerFeature__mdt> mocks = new List<TriggerFeature__mdt>();
        mocks.add(
            new TriggerFeature__mdt(
                DeveloperName = 'FeatureDoesNotExist',
                Handler__c = 'TriggerHandlerTest.FeatureDoesNotExist',
                SObjectName__c = 'Account',
                IsActive__c = true,
                LoadOrder__c = 10,
                BeforeInsert__c = true
            )
        );
        TriggerHandler.setMocks('Account', mocks);

        List<Account> accounts = getAccounts();
        Boolean expectedExceptionThrown = false;
        try {
            insert accounts;
            System.assert(false);
        } catch (Exception e) {
            expectedExceptionThrown = true;
        }
        System.assertEquals(expectedExceptionThrown, true);
    }

    @IsTest
    static void testInvalidFeature() {
        List<TriggerFeature__mdt> mocks = new List<TriggerFeature__mdt>();
        mocks.add(
            new TriggerFeature__mdt(
                DeveloperName = 'InvalidFeature',
                Handler__c = 'TriggerHandlerTest.InvalidFeature',
                SObjectName__c = 'Account',
                IsActive__c = true,
                LoadOrder__c = 10,
                BeforeInsert__c = true
            )
        );
        TriggerHandler.setMocks('Account', mocks);

        List<Account> accounts = getAccounts();
        Boolean expectedExceptionThrown = false;
        try {
            insert accounts;
            System.assert(false);
        } catch (Exception e) {
            expectedExceptionThrown = true;
        }
        System.assertEquals(expectedExceptionThrown, true);
    }

    public class AccountAddDescription implements ITriggerExecutable {
        public void execute(TriggerContext context) {
            for (Account account : (List<Account>) context.getPrimaryList()) {
                if (context.beforeInsert()) {
                    account.Description = 'Account created';
                }
            }
        }
    }

    public class AccountCreateContact implements ITriggerExecutable {
        public void execute(TriggerContext context) {
            List<Contact> contacts = new List<Contact>();
            for (Account account : (List<Account>) context.getPrimaryList()) {
                if (context.afterInsert()) {
                    contacts.add(new Contact(AccountId = account.Id, LastName = account.Name));
                }
            }
            insert contacts;
        }
    }

    public class AccountUpdateIndustry implements ITriggerExecutable {
        public void execute(TriggerContext context) {
            for (Account vAccount : (List<Account>) context.getPrimaryList()) {
                if (context.isChanged(vAccount, Account.Type) && vAccount.Type == 'Other') {
                    vAccount.Industry = 'Other';
                }
            }
        }
    }

    public class DeleteContactsAsync implements ITriggerExecutable {
        public void execute(TriggerContext context) {
            if (!context.afterDelete()) {
                return;
            }
            List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId IN :context.getRecordIds()];
            if (!contacts.isEmpty()) {
                delete contacts;
            }
        }
    }

    public class InvalidFeature {
        public void execute(TriggerContext context) {
            for (Account account : (List<Account>) context.getPrimaryList()) {
                account.Description = 'Account created';
            }
        }
    }

    private static void setupAccountMockFeatures() {
        List<TriggerFeature__mdt> mocks = new List<TriggerFeature__mdt>();
        mocks.add(
            new TriggerFeature__mdt(
                DeveloperName = 'AccountAddDescription',
                Handler__c = 'TriggerHandlerTest.AccountAddDescription',
                SObjectName__c = 'Account',
                IsActive__c = true,
                LoadOrder__c = 10,
                BeforeInsert__c = true
            )
        );
        mocks.add(
            new TriggerFeature__mdt(
                DeveloperName = 'AccountCreateContact',
                Handler__c = 'TriggerHandlerTest.AccountCreateContact',
                SObjectName__c = 'Account',
                IsActive__c = true,
                LoadOrder__c = 20,
                AfterInsert__c = true
            )
        );
        mocks.add(
            new TriggerFeature__mdt(
                DeveloperName = 'AccountUpdateIndustry',
                Handler__c = 'TriggerHandlerTest.AccountUpdateIndustry',
                SObjectName__c = 'Account',
                IsActive__c = true,
                LoadOrder__c = 20,
                BeforeUpdate__c = true
            )
        );
        mocks.add(
            new TriggerFeature__mdt(
                DeveloperName = 'DeleteContactsAsync',
                Handler__c = 'TriggerHandlerTest.DeleteContactsAsync',
                SObjectName__c = 'Account',
                IsActive__c = true,
                LoadOrder__c = 40,
                AfterDelete__c = true,
                Asynchronous__c = true
            )
        );
        TriggerHandler.setMocks('Account', mocks);
    }

    private static List<Account> getAccounts() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test1', BillingCity = 'Toronto', AccountNumber = '123', Industry = 'Technology'));
        accounts.add(new Account(Name = 'Test2', BillingCity = 'Calgary', AccountNumber = '456', Industry = 'Technology'));
        accounts.add(new Account(Name = 'Test3', BillingCity = 'Vancouver', AccountNumber = '789', Industry = 'Technology'));
        return accounts;
    }
}
