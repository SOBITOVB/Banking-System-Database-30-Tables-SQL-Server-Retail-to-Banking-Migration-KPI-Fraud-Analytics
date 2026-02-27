# Banking System (SQL Server / T-SQL)

## Run order

1. `sql/01_create_db_and_tables.sql`
2. `sql/02_insert_seed_data.sql`
3. `sql/03_kpi_queries.sql`

All scripts are Microsoft SQL Server T-SQL and are re-runnable.

## Deliverables

- `sql/01_create_db_and_tables.sql`
  - Creates `BankingSystem` database and `bank` schema
  - Creates all tables, PK/FK, UNIQUE/CHECK/DEFAULT constraints
  - Adds FK and analytical indexes
  - Uses dependency-safe `DROP TABLE IF EXISTS` for idempotency
- `sql/02_insert_seed_data.sql`
  - Uses set-based `INSERT INTO ... SELECT` generation
  - Uses reusable `#Nums` tally table
  - Preserves referential integrity with deterministic modulus FK mapping
  - Includes required fraud scenarios:
    - multiple transactions `> 10000` within `< 1 hour`
    - different countries within `10 minutes`
- `sql/03_kpi_queries.sql`
  - Top 3 customers by total balance
  - Customers with more than one active loan
  - Transactions flagged as fraudulent
  - Total loan amount issued per branch
  - Multiple large transactions within 1 hour
  - Different-country transactions within 10 minutes

## Assumptions

- `ERD` image and `banking sys.docx` are not available on-disk in this workspace path (`d:\banking_system`), so scripts follow the existing project schema baseline.
- If you provide those source files in the repo, table/column names can be aligned exactly to that source of truth.

## Expected seeded row counts

- `bank.Customers`: 10,000
- `bank.Accounts`: 25,000
- `bank.Transactions`: 241,400
- `bank.Loans`: 12,600
- `bank.LoanPayments`: 100,000
- `bank.Cards`: 18,000
- `bank.CreditCardTransactions`: 220,000
- `bank.CustomerKYC`: 10,000
- `bank.AMLCases`: 900+ (target 1,150)
- `bank.FraudDetection`: 2,800

## Quick validation queries

```sql
USE BankingSystem;
GO

SELECT 'Customers' AS TableName, COUNT(*) AS RowCount FROM bank.Customers
UNION ALL SELECT 'Accounts', COUNT(*) FROM bank.Accounts
UNION ALL SELECT 'Transactions', COUNT(*) FROM bank.[Transactions]
UNION ALL SELECT 'Loans', COUNT(*) FROM bank.Loans
UNION ALL SELECT 'LoanPayments', COUNT(*) FROM bank.LoanPayments
UNION ALL SELECT 'Cards', COUNT(*) FROM bank.Cards
UNION ALL SELECT 'CreditCardTransactions', COUNT(*) FROM bank.CreditCardTransactions
UNION ALL SELECT 'CustomerKYC', COUNT(*) FROM bank.CustomerKYC
UNION ALL SELECT 'AMLCases', COUNT(*) FROM bank.AMLCases
UNION ALL SELECT 'FraudDetection', COUNT(*) FROM bank.FraudDetection;
```

```sql
USE BankingSystem;
GO

SELECT 'Accounts->Customers' AS CheckName, COUNT(*) AS OrphanCount
FROM bank.Accounts a
LEFT JOIN bank.Customers c ON c.CustomerId = a.PrimaryCustomerId
WHERE c.CustomerId IS NULL
UNION ALL
SELECT 'Transactions->Accounts', COUNT(*)
FROM bank.[Transactions] t
LEFT JOIN bank.Accounts a ON a.AccountId = t.AccountId
WHERE a.AccountId IS NULL
UNION ALL
SELECT 'FraudDetection->Transactions', COUNT(*)
FROM bank.FraudDetection fd
LEFT JOIN bank.[Transactions] t ON t.TransactionId = fd.TransactionId
WHERE fd.TransactionId IS NOT NULL AND t.TransactionId IS NULL
UNION ALL
SELECT 'FraudDetection->CardTx', COUNT(*)
FROM bank.FraudDetection fd
LEFT JOIN bank.CreditCardTransactions cct ON cct.CardTransactionId = fd.CardTransactionId
WHERE fd.CardTransactionId IS NOT NULL AND cct.CardTransactionId IS NULL
UNION ALL
SELECT 'AMLCases->Customers', COUNT(*)
FROM bank.AMLCases aml
LEFT JOIN bank.Customers c ON c.CustomerId = aml.CustomerId
WHERE c.CustomerId IS NULL
UNION ALL
SELECT 'AMLCases->FraudDetection', COUNT(*)
FROM bank.AMLCases aml
LEFT JOIN bank.FraudDetection fd ON fd.FraudCaseId = aml.FraudCaseId
WHERE aml.FraudCaseId IS NOT NULL AND fd.FraudCaseId IS NULL;
```
