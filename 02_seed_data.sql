SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE BankingSystem;
GO

/* Purge existing data in child -> parent order */
DELETE FROM bank.ServiceTickets;
DELETE FROM bank.LoginEvents;
DELETE FROM bank.DigitalDevices;
DELETE FROM bank.DailyAccountSnapshot;
DELETE FROM bank.ExchangeRates;
DELETE FROM bank.Alerts;
DELETE FROM bank.FraudDetection;
DELETE FROM bank.LoanCollaterals;
DELETE FROM bank.LoanPayments;
DELETE FROM bank.LoanPaymentSchedule;
DELETE FROM bank.Loans;
DELETE FROM bank.CreditCardTransactions;
DELETE FROM bank.CreditCardAccounts;
DELETE FROM bank.Cards;
DELETE FROM bank.[Transactions];
DELETE FROM bank.Merchants;
DELETE FROM bank.AccountBeneficiaries;
DELETE FROM bank.AccountHolders;
DELETE FROM bank.Accounts;
DELETE FROM bank.CustomerRiskProfileHistory;
DELETE FROM bank.CustomerKYC;
DELETE FROM bank.CustomerEmployment;
DELETE FROM bank.CustomerAddressHistory;
DELETE FROM bank.CustomerContacts;
DELETE FROM bank.Customers;
DELETE FROM bank.Employees;
DELETE FROM bank.Branches;
DELETE FROM bank.Cities;
DELETE FROM bank.Countries;

DELETE FROM bank.FraudRules;
DELETE FROM bank.LoanTypes;
DELETE FROM bank.CardTypes;
DELETE FROM bank.MerchantCategories;
DELETE FROM bank.ChannelTypes;
DELETE FROM bank.TransactionTypes;
DELETE FROM bank.AccountStatus;
DELETE FROM bank.AccountTypes;
DELETE FROM bank.RiskProfiles;
DELETE FROM bank.KYCStatus;
DELETE FROM bank.CustomerSegments;
DELETE FROM bank.Departments;

DECLARE @ReseedSql NVARCHAR(MAX) = N'';
SELECT @ReseedSql = @ReseedSql
    + N'DBCC CHECKIDENT('''
    + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
    + N''', RESEED, 0) WITH NO_INFOMSGS;'
    + CHAR(10)
FROM sys.tables t
JOIN sys.identity_columns ic ON ic.object_id = t.object_id
WHERE SCHEMA_NAME(t.schema_id) = N'bank';
EXEC sys.sp_executesql @ReseedSql;

/* Dimensions */
INSERT INTO bank.Countries (CountryCode, CountryName, Region)
VALUES
('US', N'United States', N'North America'),
('CA', N'Canada', N'North America'),
('GB', N'United Kingdom', N'Europe'),
('DE', N'Germany', N'Europe'),
('FR', N'France', N'Europe'),
('AE', N'United Arab Emirates', N'Middle East'),
('IN', N'India', N'Asia'),
('SG', N'Singapore', N'Asia'),
('UZ', N'Uzbekistan', N'Asia'),
('JP', N'Japan', N'Asia'),
('AU', N'Australia', N'Oceania'),
('BR', N'Brazil', N'South America');

INSERT INTO bank.Cities (CountryId, CityName, StateProvince)
SELECT c.CountryId, v.CityName, v.StateProvince
FROM (VALUES
    ('US', N'New York', N'NY'),
    ('US', N'Los Angeles', N'CA'),
    ('CA', N'Toronto', N'ON'),
    ('CA', N'Vancouver', N'BC'),
    ('GB', N'London', N'England'),
    ('GB', N'Manchester', N'England'),
    ('DE', N'Berlin', N'Berlin'),
    ('DE', N'Frankfurt', N'Hesse'),
    ('FR', N'Paris', N'IDF'),
    ('FR', N'Lyon', N'Auvergne-Rhone-Alpes'),
    ('AE', N'Dubai', N'Dubai'),
    ('AE', N'Abu Dhabi', N'Abu Dhabi'),
    ('IN', N'Mumbai', N'Maharashtra'),
    ('IN', N'Bengaluru', N'Karnataka'),
    ('SG', N'Singapore', N'SG'),
    ('SG', N'Jurong East', N'SG'),
    ('UZ', N'Tashkent', N'Tashkent'),
    ('UZ', N'Samarkand', N'Samarkand'),
    ('JP', N'Tokyo', N'Tokyo'),
    ('JP', N'Osaka', N'Osaka'),
    ('AU', N'Sydney', N'NSW'),
    ('AU', N'Melbourne', N'VIC'),
    ('BR', N'Sao Paulo', N'SP'),
    ('BR', N'Rio de Janeiro', N'RJ')
) AS v(CountryCode, CityName, StateProvince)
JOIN bank.Countries c
    ON c.CountryCode = v.CountryCode;

;WITH N AS
(
    SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO bank.Branches (BranchCode, BranchName, CityId, AddressLine1, PhoneNumber, OpenedDate, IsActive, CreatedAt, UpdatedAt)
SELECT
    CONCAT('BR', RIGHT('000' + CAST(n AS VARCHAR(3)), 3)),
    CONCAT(N'Branch ', n),
    ((n - 1) % 24) + 1,
    CONCAT(CAST(n AS VARCHAR(4)), N' Financial Ave'),
    CONCAT('+1-800-', RIGHT('0000' + CAST(1000 + n AS VARCHAR(4)), 4)),
    DATEADD(DAY, -(n * 20), CAST(SYSUTCDATETIME() AS DATE)),
    1,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM N;

INSERT INTO bank.Departments (DepartmentName)
VALUES
(N'Retail Banking'),
(N'Corporate Banking'),
(N'Risk Management'),
(N'Compliance'),
(N'Operations'),
(N'Customer Support');

INSERT INTO bank.CustomerSegments (SegmentName, Description)
VALUES
(N'Retail', N'General retail customers'),
(N'Premium', N'Affluent segment'),
(N'SME', N'Small and medium enterprise owners'),
(N'Corporate', N'Enterprise profile customers');

INSERT INTO bank.KYCStatus (StatusName, Description)
VALUES
(N'Verified', N'KYC completed and verified'),
(N'Pending', N'Awaiting additional documents'),
(N'Expired', N'KYC expired and needs refresh'),
(N'Rejected', N'KYC failed due to mismatch');

INSERT INTO bank.RiskProfiles (RiskLevel, ScoreMin, ScoreMax)
VALUES
('Low', 0, 249),
('Medium', 250, 499),
('High', 500, 749),
('Critical', 750, 1000);

INSERT INTO bank.AccountTypes (AccountTypeName, Description)
VALUES
(N'Checking', N'Daily transaction account'),
(N'Savings', N'Interest-bearing account'),
(N'Business', N'Business operating account'),
(N'Salary', N'Payroll account');

INSERT INTO bank.AccountStatus (StatusName, Description)
VALUES
(N'Active', N'Account is active'),
(N'Dormant', N'No activity for a long period'),
(N'Frozen', N'Temporary hold'),
(N'Closed', N'Account is closed');

INSERT INTO bank.TransactionTypes (TypeName, Description)
VALUES
(N'Deposit', N'Cash or transfer deposit'),
(N'Withdrawal', N'Cash withdrawal'),
(N'Transfer', N'Account to account transfer'),
(N'CardPayment', N'POS or online card payment'),
(N'BillPayment', N'Bill settlement'),
(N'Fee', N'Bank fee');

INSERT INTO bank.ChannelTypes (ChannelName, Description)
VALUES
(N'Mobile', N'Mobile app channel'),
(N'Online', N'Internet banking'),
(N'ATM', N'ATM channel'),
(N'Branch', N'Branch teller'),
(N'POS', N'Point of sale'),
(N'API', N'External API channel');

INSERT INTO bank.MerchantCategories (CategoryName, Description)
VALUES
(N'Groceries', N'Food and groceries'),
(N'Electronics', N'Electronics stores'),
(N'Travel', N'Travel and hospitality'),
(N'Utilities', N'Utilities and telecom'),
(N'Healthcare', N'Healthcare services'),
(N'Education', N'Education services'),
(N'Restaurants', N'Food and dining'),
(N'Fuel', N'Gas stations'),
(N'Entertainment', N'Entertainment'),
(N'Misc', N'Other merchants');

INSERT INTO bank.CardTypes (CardTypeName, IsCredit)
VALUES
(N'Debit', 0),
(N'Credit', 1),
(N'VirtualCredit', 1);

INSERT INTO bank.LoanTypes (LoanTypeName, Description)
VALUES
(N'Personal', N'Unsecured personal loan'),
(N'Auto', N'Car financing'),
(N'Mortgage', N'Home financing'),
(N'Education', N'Education loan'),
(N'Business', N'Business term loan');

INSERT INTO bank.FraudRules (RuleCode, RuleName, RuleDescription)
VALUES
('LARGE_TXN_1H', N'Multiple Large Transactions in 1 Hour', N'More than one transaction over $10,000 within less than 1 hour'),
('GEO_VELOCITY_10M', N'Country Mismatch in 10 Minutes', N'Transactions from different countries within 10 minutes'),
('CARD_ANOMALY', N'Card Transaction Anomaly', N'High risk card transaction pattern'),
('HIGH_RISK_MERCHANT', N'High Risk Merchant Rule', N'Transaction involving high risk merchant category'),
('MANUAL_REVIEW', N'Manual Review Trigger', N'Suspicious activity sent for manual review');

IF OBJECT_ID('tempdb..#Nums') IS NOT NULL
    DROP TABLE #Nums;

SELECT TOP (400000)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #Nums
FROM sys.all_objects a
CROSS JOIN sys.all_objects b;

CREATE UNIQUE CLUSTERED INDEX IX_Nums_n ON #Nums (n);

/* Employees */
INSERT INTO bank.Employees
(
    BranchId,
    DepartmentId,
    ManagerEmployeeId,
    FirstName,
    LastName,
    Email,
    JobTitle,
    HireDate,
    IsActive,
    CreatedAt,
    UpdatedAt
)
SELECT
    ((n - 1) % 60) + 1,
    ((n - 1) % 6) + 1,
    NULL,
    CONCAT(N'EmpFirst', n),
    CONCAT(N'EmpLast', n),
    CONCAT('employee', RIGHT('0000' + CAST(n AS VARCHAR(4)), 4), '@bank.test'),
    N'Bank Officer',
    DATEADD(DAY, -(n % 3650), CAST(SYSUTCDATETIME() AS DATE)),
    CASE WHEN n % 20 = 0 THEN 0 ELSE 1 END,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM #Nums
WHERE n <= 1200;

UPDATE e
SET e.ManagerEmployeeId = CASE WHEN e.EmployeeId % 20 = 1 THEN NULL ELSE e.EmployeeId - 1 END
FROM bank.Employees e
WHERE e.EmployeeId > 1;

/* Customers and customer-level entities */
INSERT INTO bank.Customers
(
    CustomerNumber,
    FirstName,
    LastName,
    DateOfBirth,
    Gender,
    NationalId,
    TaxId,
    SegmentId,
    HomeBranchId,
    OnboardingDate,
    Status,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('C', RIGHT('00000000' + CAST(n AS VARCHAR(8)), 8)),
    CHOOSE(((n - 1) % 12) + 1, N'Liam', N'Noah', N'Emma', N'Olivia', N'Ava', N'Mia', N'Ethan', N'Sophia', N'Lucas', N'Amelia', N'James', N'Harper'),
    CHOOSE(((n + 3) % 12) + 1, N'Smith', N'Johnson', N'Williams', N'Brown', N'Jones', N'Garcia', N'Miller', N'Davis', N'Wilson', N'Taylor', N'Anderson', N'Thomas'),
    DATEADD(DAY, -(7300 + (n % 18000)), CAST('2026-01-01' AS DATE)),
    CASE WHEN n % 2 = 0 THEN 'F' ELSE 'M' END,
    CONCAT('NID', RIGHT('000000000' + CAST(n AS VARCHAR(9)), 9)),
    CASE WHEN n % 4 = 0 THEN NULL ELSE CONCAT('TIN', RIGHT('000000000' + CAST(n AS VARCHAR(9)), 9)) END,
    ((n - 1) % 4) + 1,
    ((n - 1) % 60) + 1,
    DATEADD(DAY, -(n % 730), CAST(SYSUTCDATETIME() AS DATE)),
    CASE WHEN n % 401 = 0 THEN 'Closed' WHEN n % 97 = 0 THEN 'Inactive' ELSE 'Active' END,
    DATEADD(DAY, -(n % 730), SYSUTCDATETIME()),
    SYSUTCDATETIME()
FROM #Nums
WHERE n <= 10000;

INSERT INTO bank.CustomerContacts (CustomerId, ContactType, ContactValue, IsPrimary, VerifiedAt, CreatedAt)
SELECT
    c.CustomerId,
    'Email',
    LOWER(CONCAT('customer', c.CustomerId, '@examplebank.test')),
    1,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM bank.Customers c;

INSERT INTO bank.CustomerContacts (CustomerId, ContactType, ContactValue, IsPrimary, VerifiedAt, CreatedAt)
SELECT
    c.CustomerId,
    'Phone',
    CONCAT('+1-202-', RIGHT('0000000' + CAST(1000000 + c.CustomerId AS VARCHAR(7)), 7)),
    0,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM bank.Customers c;

INSERT INTO bank.CustomerAddressHistory
(
    CustomerId,
    AddressLine1,
    CityId,
    PostalCode,
    CountryId,
    ValidFrom,
    ValidTo,
    IsCurrent,
    CreatedAt
)
SELECT
    c.CustomerId,
    CONCAT(c.CustomerId, N' Main Street'),
    br.CityId,
    RIGHT('00000' + CAST((10000 + (c.CustomerId % 89999)) AS VARCHAR(5)), 5),
    ci.CountryId,
    c.OnboardingDate,
    NULL,
    1,
    SYSUTCDATETIME()
FROM bank.Customers c
JOIN bank.Branches br ON br.BranchId = c.HomeBranchId
JOIN bank.Cities ci ON ci.CityId = br.CityId;

INSERT INTO bank.CustomerEmployment
(
    CustomerId,
    EmployerName,
    Occupation,
    AnnualIncome,
    EmploymentStatus,
    StartDate,
    EndDate,
    CreatedAt
)
SELECT
    c.CustomerId,
    CONCAT(N'Employer ', (c.CustomerId % 2500) + 1),
    CHOOSE((c.CustomerId % 6) + 1, N'Engineer', N'Teacher', N'Consultant', N'Analyst', N'Manager', N'Operator'),
    CAST(25000 + ((c.CustomerId % 220000) * 1.00) AS DECIMAL(18,2)),
    CASE WHEN c.CustomerId % 23 = 0 THEN 'SelfEmployed' ELSE 'Employed' END,
    DATEADD(DAY, -((c.CustomerId % 3650) + 30), CAST(SYSUTCDATETIME() AS DATE)),
    NULL,
    SYSUTCDATETIME()
FROM bank.Customers c
WHERE c.CustomerId % 10 < 7;

INSERT INTO bank.CustomerKYC
(
    CustomerId,
    KYCStatusId,
    DocumentType,
    DocumentNumber,
    VerifiedByEmployeeId,
    VerificationDate,
    ExpiryDate,
    CreatedAt,
    UpdatedAt
)
SELECT
    c.CustomerId,
    CASE WHEN c.CustomerId % 29 = 0 THEN 2 WHEN c.CustomerId % 41 = 0 THEN 3 WHEN c.CustomerId % 211 = 0 THEN 4 ELSE 1 END,
    CHOOSE((c.CustomerId % 4) + 1, 'Passport', 'NationalId', 'DriverLicense', 'ResidencePermit'),
    CONCAT('DOC', RIGHT('0000000000' + CAST(c.CustomerId AS VARCHAR(10)), 10)),
    ((c.CustomerId - 1) % 1200) + 1,
    DATEADD(DAY, -(c.CustomerId % 600), SYSUTCDATETIME()),
    DATEADD(DAY, 365 + (c.CustomerId % 365), CAST(SYSUTCDATETIME() AS DATE)),
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM bank.Customers c;

INSERT INTO bank.CustomerRiskProfileHistory
(
    CustomerId,
    RiskProfileId,
    EffectiveFrom,
    EffectiveTo,
    Reason,
    CreatedAt
)
SELECT
    c.CustomerId,
    CASE
        WHEN c.CustomerId % 100 < 60 THEN 1
        WHEN c.CustomerId % 100 < 88 THEN 2
        WHEN c.CustomerId % 100 < 97 THEN 3
        ELSE 4
    END,
    DATEADD(DAY, -(c.CustomerId % 730), SYSUTCDATETIME()),
    NULL,
    N'Initial onboarding score',
    SYSUTCDATETIME()
FROM bank.Customers c;

/* Accounts */
INSERT INTO bank.Accounts
(
    AccountNumber,
    PrimaryCustomerId,
    BranchId,
    AccountTypeId,
    AccountStatusId,
    CurrencyCode,
    OpenedDate,
    ClosedDate,
    CurrentBalance,
    AvailableBalance,
    OverdraftLimit,
    InterestRate,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('AC', RIGHT('0000000000' + CAST(n.n AS VARCHAR(10)), 10)),
    ((n.n - 1) % 10000) + 1,
    ((n.n - 1) % 60) + 1,
    ((n.n - 1) % 4) + 1,
    CASE WHEN n.n % 71 = 0 THEN 4 WHEN n.n % 31 = 0 THEN 3 WHEN n.n % 17 = 0 THEN 2 ELSE 1 END,
    CASE
        WHEN n.n % 10 IN (0, 1, 2, 3, 4, 5) THEN 'USD'
        WHEN n.n % 10 IN (6, 7) THEN 'EUR'
        WHEN n.n % 10 = 8 THEN 'GBP'
        ELSE 'UZS'
    END,
    DATEADD(DAY, -(n.n % 730), CAST(SYSUTCDATETIME() AS DATE)),
    NULL,
    bal.CurrentBalance,
    CASE WHEN bal.CurrentBalance - bal.HoldAmount < 0 THEN bal.CurrentBalance ELSE bal.CurrentBalance - bal.HoldAmount END,
    CASE WHEN ((n.n - 1) % 4) + 1 IN (1, 3) THEN 1000.00 ELSE 0.00 END,
    CASE WHEN ((n.n - 1) % 4) + 1 = 2 THEN 1.50 WHEN ((n.n - 1) % 4) + 1 = 4 THEN 0.50 ELSE 0.00 END,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM #Nums n
CROSS APPLY
(
    SELECT
        CAST(ROUND((ABS(CHECKSUM(n.n * 31)) % 5000000) / 100.0 + 100.0, 2) AS DECIMAL(19,2)) AS CurrentBalance,
        CAST(ROUND((ABS(CHECKSUM(n.n * 47)) % 30000) / 100.0, 2) AS DECIMAL(19,2)) AS HoldAmount
) bal
WHERE n.n <= 25000;

INSERT INTO bank.AccountHolders
(
    AccountId,
    CustomerId,
    HolderRole,
    OwnershipPercent,
    IsPrimary,
    StartDate,
    EndDate,
    CreatedAt
)
SELECT
    a.AccountId,
    a.PrimaryCustomerId,
    'Primary',
    100.00,
    1,
    a.OpenedDate,
    NULL,
    SYSUTCDATETIME()
FROM bank.Accounts a;

INSERT INTO bank.AccountHolders
(
    AccountId,
    CustomerId,
    HolderRole,
    OwnershipPercent,
    IsPrimary,
    StartDate,
    EndDate,
    CreatedAt
)
SELECT
    a.AccountId,
    CASE WHEN a.PrimaryCustomerId = 10000 THEN 1 ELSE a.PrimaryCustomerId + 1 END,
    'Joint',
    50.00,
    0,
    a.OpenedDate,
    NULL,
    SYSUTCDATETIME()
FROM bank.Accounts a
WHERE a.AccountId % 5 = 0;

INSERT INTO bank.AccountBeneficiaries (AccountId, BeneficiaryCustomerId, RelationshipType, IsActive, CreatedAt)
SELECT
    a.AccountId,
    ((a.PrimaryCustomerId + 321 - 1) % 10000) + 1,
    CASE WHEN a.AccountId % 3 = 0 THEN 'Spouse' ELSE 'Relative' END,
    1,
    SYSUTCDATETIME()
FROM bank.Accounts a
WHERE a.AccountId % 2 = 0;

/* Merchants and transactions */
;WITH M AS
(
    SELECT TOP (500) n
    FROM #Nums
    ORDER BY n
)
INSERT INTO bank.Merchants (MerchantName, MerchantCategoryId, CityId, CountryId, IsHighRisk, CreatedAt)
SELECT
    CONCAT(N'Merchant ', m.n),
    ((m.n - 1) % 10) + 1,
    ((m.n - 1) % 24) + 1,
    ci.CountryId,
    CASE WHEN m.n % 17 = 0 THEN 1 ELSE 0 END,
    SYSUTCDATETIME()
FROM M m
JOIN bank.Cities ci ON ci.CityId = ((m.n - 1) % 24) + 1;

INSERT INTO bank.[Transactions]
(
    AccountId,
    TransactionTypeId,
    ChannelId,
    MerchantId,
    CounterpartyAccountId,
    Amount,
    CurrencyCode,
    TransactionDate,
    CountryId,
    CityId,
    TransactionStatus,
    Description,
    IsReversed,
    CreatedAt,
    UpdatedAt
)
SELECT
    a.AccountId,
    ((n.n - 1) % 6) + 1,
    ((n.n - 1) % 6) + 1,
    CASE WHEN ((n.n - 1) % 6) + 1 IN (4, 5) THEN ((n.n - 1) % 500) + 1 ELSE NULL END,
    CASE WHEN ((n.n - 1) % 6) + 1 = 3 THEN ((a.AccountId + n.n) % 25000) + 1 ELSE NULL END,
    tx.Amount,
    a.CurrencyCode,
    tx.TransactionDate,
    ci.CountryId,
    br.CityId,
    CASE WHEN n.n % 89 = 0 THEN 'Declined' WHEN n.n % 41 = 0 THEN 'Pending' ELSE 'Posted' END,
    CONCAT(N'Synthetic account transaction ', n.n),
    CASE WHEN n.n % 211 = 0 THEN 1 ELSE 0 END,
    tx.TransactionDate,
    tx.TransactionDate
FROM #Nums n
JOIN bank.Accounts a ON a.AccountId = ((n.n - 1) % 25000) + 1
JOIN bank.Branches br ON br.BranchId = a.BranchId
JOIN bank.Cities ci ON ci.CityId = br.CityId
CROSS APPLY
(
    SELECT
        CAST(
            CASE
                WHEN n.n % 200 = 0 THEN 12000 + (n.n % 9000)
                WHEN n.n % 25 = 0 THEN 2000 + (n.n % 7000)
                ELSE 10 + (n.n % 1800)
            END
            + ((n.n % 100) / 100.0)
        AS DECIMAL(19,2)) AS Amount,
        DATEADD(MINUTE, -(n.n % 1051200), SYSUTCDATETIME()) AS TransactionDate
) tx
WHERE n.n <= 240000;

/* Cards */
INSERT INTO bank.Cards
(
    AccountId,
    CustomerId,
    CardTypeId,
    CardNumber,
    MaskedCardNumber,
    CVVToken,
    ExpiryMonth,
    ExpiryYear,
    IssuedDate,
    DailyLimit,
    IsActive,
    CreatedAt,
    UpdatedAt
)
SELECT
    a.AccountId,
    a.PrimaryCustomerId,
    CASE WHEN n.n % 4 = 0 THEN 2 WHEN n.n % 11 = 0 THEN 3 ELSE 1 END,
    CONCAT('5400', RIGHT('000000000000' + CAST(n.n AS VARCHAR(12)), 12)),
    CONCAT('5400********', RIGHT('0000' + CAST(n.n % 10000 AS VARCHAR(4)), 4)),
    CONCAT('FAKE_CVV_', RIGHT('000000' + CAST(n.n AS VARCHAR(6)), 6)),
    ((n.n - 1) % 12) + 1,
    YEAR(SYSUTCDATETIME()) + 2 + (n.n % 4),
    DATEADD(DAY, -(n.n % 720), CAST(SYSUTCDATETIME() AS DATE)),
    CASE WHEN n.n % 4 = 0 THEN 8000.00 WHEN n.n % 11 = 0 THEN 5000.00 ELSE 2500.00 END,
    CASE WHEN n.n % 19 = 0 THEN 0 ELSE 1 END,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM #Nums n
JOIN bank.Accounts a ON a.AccountId = ((n.n - 1) % 25000) + 1
WHERE n.n <= 18000;

INSERT INTO bank.CreditCardAccounts
(
    CardId,
    CreditLimit,
    AvailableCredit,
    APR,
    BillingCycleDay,
    CurrentDueAmount,
    LastStatementDate,
    PaymentDueDate,
    Status,
    CreatedAt,
    UpdatedAt
)
SELECT
    c.CardId,
    CAST(2000 + (c.CardId % 20000) AS DECIMAL(19,2)),
    CAST((2000 + (c.CardId % 20000)) * 0.65 AS DECIMAL(19,2)),
    CAST(12.50 + ((c.CardId % 120) / 10.0) AS DECIMAL(5,2)),
    ((c.CardId - 1) % 28) + 1,
    CAST((2000 + (c.CardId % 20000)) * 0.18 AS DECIMAL(19,2)),
    DATEADD(DAY, -30, CAST(SYSUTCDATETIME() AS DATE)),
    DATEADD(DAY, 15, CAST(SYSUTCDATETIME() AS DATE)),
    CASE WHEN c.CardId % 27 = 0 THEN 'Blocked' ELSE 'Active' END,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM bank.Cards c
WHERE c.CardTypeId IN (2, 3);

INSERT INTO bank.CreditCardTransactions
(
    CardId,
    MerchantId,
    ChannelId,
    Amount,
    CurrencyCode,
    TransactionDate,
    CountryId,
    CityId,
    IsCardPresent,
    IsInternational,
    TransactionStatus,
    AuthCode,
    CreatedAt,
    UpdatedAt
)
SELECT
    c.CardId,
    ((n.n - 1) % 500) + 1,
    ((n.n - 1) % 6) + 1,
    CAST(
        CASE
            WHEN n.n % 150 = 0 THEN 5000 + (n.n % 4000)
            WHEN n.n % 35 = 0 THEN 800 + (n.n % 2500)
            ELSE 5 + (n.n % 700)
        END
        + ((n.n % 100) / 100.0)
    AS DECIMAL(19,2)),
    CASE WHEN n.n % 10 IN (0, 1, 2, 3, 4, 5) THEN 'USD' WHEN n.n % 10 IN (6, 7) THEN 'EUR' ELSE 'GBP' END,
    DATEADD(MINUTE, -(n.n % 1051200), SYSUTCDATETIME()),
    CASE WHEN n.n % 20 = 0 THEN alt.CountryId ELSE ci.CountryId END,
    CASE WHEN n.n % 20 = 0 THEN alt.CityId ELSE ci.CityId END,
    CASE WHEN n.n % 4 = 0 THEN 0 ELSE 1 END,
    CASE WHEN n.n % 20 = 0 THEN 1 ELSE 0 END,
    CASE WHEN n.n % 53 = 0 THEN 'Declined' ELSE 'Approved' END,
    CONCAT('AUTH', RIGHT('000000000' + CAST(n.n AS VARCHAR(9)), 9)),
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM #Nums n
JOIN bank.Cards c ON c.CardId = ((n.n - 1) % 18000) + 1
JOIN bank.Accounts a ON a.AccountId = c.AccountId
JOIN bank.Branches br ON br.BranchId = a.BranchId
JOIN bank.Cities ci ON ci.CityId = br.CityId
OUTER APPLY
(
    SELECT TOP (1)
        c2.CountryId,
        c2.CityId
    FROM bank.Cities c2
    WHERE c2.CountryId <> ci.CountryId
    ORDER BY c2.CountryId, c2.CityId
) alt
WHERE n.n <= 220000;

/* Loans */
INSERT INTO bank.Loans
(
    CustomerId,
    BranchId,
    LoanTypeId,
    PrincipalAmount,
    InterestRate,
    TermMonths,
    StartDate,
    MaturityDate,
    LoanStatus,
    OutstandingPrincipal,
    MonthlyInstallment,
    CreatedAt,
    UpdatedAt
)
SELECT
    ((n.n - 1) % 10000) + 1,
    ((n.n - 1) % 60) + 1,
    ((n.n - 1) % 5) + 1,
    l.PrincipalAmount,
    l.InterestRate,
    l.TermMonths,
    l.StartDate,
    DATEADD(MONTH, l.TermMonths, l.StartDate),
    CASE WHEN n.n % 10 = 0 THEN 'Delinquent' WHEN n.n % 6 = 0 THEN 'Closed' ELSE 'Active' END,
    CASE WHEN n.n % 6 = 0 THEN 0.00 ELSE CAST(l.PrincipalAmount * (0.30 + ((n.n % 40) / 100.0)) AS DECIMAL(19,2)) END,
    CAST((l.PrincipalAmount / l.TermMonths) + (l.PrincipalAmount * l.InterestRate / 1200.0) AS DECIMAL(19,2)),
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM #Nums n
CROSS APPLY
(
    SELECT
        CAST(3000 + (ABS(CHECKSUM(n.n * 19)) % 250000) AS DECIMAL(19,2)) AS PrincipalAmount,
        CAST(4.00 + ((n.n % 120) / 10.0) AS DECIMAL(5,2)) AS InterestRate,
        CASE n.n % 6
            WHEN 0 THEN 12
            WHEN 1 THEN 24
            WHEN 2 THEN 36
            WHEN 3 THEN 48
            WHEN 4 THEN 60
            ELSE 84
        END AS TermMonths,
        DATEADD(DAY, -(n.n % 700), CAST(SYSUTCDATETIME() AS DATE)) AS StartDate
) l
WHERE n.n <= 12000;

;WITH TargetCustomers AS
(
    SELECT TOP (300) CustomerId
    FROM bank.Customers
    ORDER BY CustomerId
),
LoanCopies AS
(
    SELECT 1 AS LoanNo
    UNION ALL
    SELECT 2 AS LoanNo
)
INSERT INTO bank.Loans
(
    CustomerId,
    BranchId,
    LoanTypeId,
    PrincipalAmount,
    InterestRate,
    TermMonths,
    StartDate,
    MaturityDate,
    LoanStatus,
    OutstandingPrincipal,
    MonthlyInstallment,
    CreatedAt,
    UpdatedAt
)
SELECT
    tc.CustomerId,
    ((tc.CustomerId - 1) % 60) + 1,
    ((lc.LoanNo - 1) % 5) + 1,
    CAST(15000 + ((tc.CustomerId * lc.LoanNo) % 20000) AS DECIMAL(19,2)),
    CAST(8.50 + (lc.LoanNo * 0.5) AS DECIMAL(5,2)),
    36,
    DATEADD(DAY, -(tc.CustomerId % 300), CAST(SYSUTCDATETIME() AS DATE)),
    DATEADD(MONTH, 36, DATEADD(DAY, -(tc.CustomerId % 300), CAST(SYSUTCDATETIME() AS DATE))),
    'Active',
    CAST(12000 + ((tc.CustomerId * lc.LoanNo) % 15000) AS DECIMAL(19,2)),
    CAST(600 + ((tc.CustomerId * lc.LoanNo) % 350) AS DECIMAL(19,2)),
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM TargetCustomers tc
CROSS JOIN LoanCopies lc;

;WITH Installments AS
(
    SELECT 1 AS InstallmentNo UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
INSERT INTO bank.LoanPaymentSchedule
(
    LoanId,
    InstallmentNo,
    DueDate,
    DueAmount,
    PrincipalComponent,
    InterestComponent,
    ScheduleStatus,
    CreatedAt
)
SELECT
    l.LoanId,
    i.InstallmentNo,
    DATEADD(MONTH, i.InstallmentNo, l.StartDate),
    CAST(l.MonthlyInstallment AS DECIMAL(19,2)),
    CAST(l.PrincipalAmount / l.TermMonths AS DECIMAL(19,2)),
    CAST(l.PrincipalAmount * l.InterestRate / 1200.0 AS DECIMAL(19,2)),
    CASE
        WHEN DATEADD(MONTH, i.InstallmentNo, l.StartDate) > CAST(SYSUTCDATETIME() AS DATE) THEN 'Planned'
        WHEN i.InstallmentNo % 5 = 0 THEN 'Overdue'
        ELSE 'Due'
    END,
    SYSUTCDATETIME()
FROM bank.Loans l
JOIN Installments i
    ON i.InstallmentNo <= CASE WHEN l.TermMonths < 12 THEN l.TermMonths ELSE 12 END;

INSERT TOP (100000) INTO bank.LoanPayments
(
    LoanId,
    ScheduleId,
    PaymentDate,
    AmountPaid,
    PaymentChannelId,
    PaymentStatus,
    ReferenceNo,
    CreatedAt
)
SELECT
    s.LoanId,
    s.ScheduleId,
    CASE WHEN s.DueDate < CAST(SYSUTCDATETIME() AS DATE) THEN DATEADD(DAY, -(s.ScheduleId % 4), s.DueDate) ELSE s.DueDate END,
    CASE WHEN s.ScheduleId % 17 = 0 THEN CAST(s.DueAmount * 0.60 AS DECIMAL(19,2)) ELSE s.DueAmount END,
    ((s.ScheduleId - 1) % 6) + 1,
    CASE WHEN s.ScheduleId % 17 = 0 THEN 'Partial' ELSE 'Completed' END,
    CONCAT('LP', RIGHT('0000000000' + CAST(s.ScheduleId AS VARCHAR(10)), 10)),
    SYSUTCDATETIME()
FROM bank.LoanPaymentSchedule s
ORDER BY s.ScheduleId;

INSERT INTO bank.LoanCollaterals (LoanId, CollateralType, EstimatedValue, RegisteredDate, Description, CreatedAt)
SELECT
    l.LoanId,
    CASE l.LoanTypeId
        WHEN 2 THEN 'Vehicle'
        WHEN 3 THEN 'Property'
        WHEN 5 THEN 'BusinessAsset'
        ELSE 'Deposit'
    END,
    CAST(l.PrincipalAmount * 1.20 AS DECIMAL(19,2)),
    DATEADD(DAY, 3, l.StartDate),
    N'Auto-generated collateral',
    SYSUTCDATETIME()
FROM bank.Loans l
WHERE l.LoanTypeId IN (2, 3, 5)
  AND l.LoanId % 2 = 0;

/* Exchange rates */
;WITH D AS
(
    SELECT TOP (730) n
    FROM #Nums
    ORDER BY n
),
Pairs AS
(
    SELECT 'USD' AS FromCurrency, 'EUR' AS ToCurrency, CAST(0.92 AS DECIMAL(18,8)) AS BaseRate, CAST(0.0005 AS DECIMAL(18,8)) AS Vol
    UNION ALL SELECT 'USD', 'GBP', 0.79, 0.0004
    UNION ALL SELECT 'USD', 'JPY', 149.00, 0.0800
    UNION ALL SELECT 'USD', 'UZS', 12600.00, 3.0000
    UNION ALL SELECT 'EUR', 'USD', 1.08, 0.0006
    UNION ALL SELECT 'GBP', 'USD', 1.26, 0.0007
)
INSERT INTO bank.ExchangeRates (RateDate, FromCurrency, ToCurrency, Rate, SourceSystem, CreatedAt)
SELECT
    DATEADD(DAY, -(d.n - 1), CAST(SYSUTCDATETIME() AS DATE)),
    p.FromCurrency,
    p.ToCurrency,
    CAST(p.BaseRate + ((d.n % 25) - 12) * p.Vol AS DECIMAL(18,8)),
    'SyntheticFeed',
    SYSUTCDATETIME()
FROM D d
CROSS JOIN Pairs p;

/* Daily account snapshots */
;WITH D AS
(
    SELECT TOP (30) n
    FROM #Nums
    ORDER BY n
),
A AS
(
    SELECT TOP (5000) AccountId, CurrentBalance, AvailableBalance
    FROM bank.Accounts
    ORDER BY AccountId
)
INSERT INTO bank.DailyAccountSnapshot
(
    AccountId,
    SnapshotDate,
    EndOfDayBalance,
    AvailableBalance,
    DebitTurnover,
    CreditTurnover,
    CreatedAt
)
SELECT
    a.AccountId,
    DATEADD(DAY, -d.n, CAST(SYSUTCDATETIME() AS DATE)),
    CAST(a.CurrentBalance + ((d.n % 9) - 4) * 15.00 AS DECIMAL(19,2)),
    CAST(a.AvailableBalance + ((d.n % 7) - 3) * 10.00 AS DECIMAL(19,2)),
    CAST((d.n % 13) * 45.25 AS DECIMAL(19,2)),
    CAST((d.n % 11) * 48.10 AS DECIMAL(19,2)),
    SYSUTCDATETIME()
FROM A a
CROSS JOIN D d;

/* Devices and login events */
INSERT INTO bank.DigitalDevices
(
    CustomerId,
    DeviceFingerprint,
    DeviceType,
    FirstSeenAt,
    LastSeenAt,
    IsTrusted,
    CreatedAt
)
SELECT
    ((n.n - 1) % 10000) + 1,
    CONCAT('DEV-', RIGHT('0000000000' + CAST(n.n AS VARCHAR(10)), 10)),
    CHOOSE(((n.n - 1) % 5) + 1, 'Mobile', 'Desktop', 'Tablet', 'ATM', 'POS'),
    d.FirstSeenAt,
    d.LastSeenAt,
    CASE WHEN n.n % 7 = 0 THEN 1 ELSE 0 END,
    SYSUTCDATETIME()
FROM #Nums n
CROSS APPLY
(
    SELECT
        DATEADD(DAY, -(n.n % 700), SYSUTCDATETIME()) AS FirstSeenAt,
        CASE
            WHEN DATEADD(DAY, (n.n % 60), DATEADD(DAY, -(n.n % 700), SYSUTCDATETIME())) > SYSUTCDATETIME()
                THEN SYSUTCDATETIME()
            ELSE DATEADD(DAY, (n.n % 60), DATEADD(DAY, -(n.n % 700), SYSUTCDATETIME()))
        END AS LastSeenAt
) d
WHERE n.n <= 15000;

INSERT INTO bank.LoginEvents
(
    CustomerId,
    DeviceId,
    ChannelId,
    LoginTime,
    CountryId,
    CityId,
    Success,
    IPAddress,
    CreatedAt
)
SELECT
    c.CustomerId,
    CASE WHEN n.n % 6 = 0 THEN NULL ELSE ((n.n - 1) % 15000) + 1 END,
    ((n.n - 1) % 6) + 1,
    DATEADD(MINUTE, -(n.n % 1051200), SYSUTCDATETIME()),
    ci.CountryId,
    ci.CityId,
    CASE WHEN n.n % 12 = 0 THEN 0 ELSE 1 END,
    CONCAT('10.', (n.n % 255), '.', ((n.n / 255) % 255), '.', ((n.n / 65025) % 255)),
    SYSUTCDATETIME()
FROM #Nums n
JOIN bank.Customers c ON c.CustomerId = ((n.n - 1) % 10000) + 1
JOIN bank.Branches br ON br.BranchId = c.HomeBranchId
JOIN bank.Cities ci ON ci.CityId = br.CityId
WHERE n.n <= 120000;

/* Service tickets */
DECLARE @MaxLoanId INT = (SELECT MAX(LoanId) FROM bank.Loans);

INSERT INTO bank.ServiceTickets
(
    CustomerId,
    RelatedAccountId,
    RelatedLoanId,
    CreatedByEmployeeId,
    TicketType,
    Priority,
    Status,
    OpenedAt,
    ClosedAt,
    Summary,
    CreatedAt
)
SELECT
    ((n.n - 1) % 10000) + 1,
    CASE WHEN n.n % 2 = 0 THEN ((n.n - 1) % 25000) + 1 ELSE NULL END,
    CASE WHEN n.n % 5 = 0 THEN ((n.n - 1) % @MaxLoanId) + 1 ELSE NULL END,
    CASE WHEN n.n % 3 = 0 THEN ((n.n - 1) % 1200) + 1 ELSE NULL END,
    CHOOSE(((n.n - 1) % 4) + 1, 'GeneralInquiry', 'CardIssue', 'LoanIssue', 'Dispute'),
    CHOOSE(((n.n - 1) % 4) + 1, 'Low', 'Medium', 'High', 'Critical'),
    st.StatusName,
    st.OpenedAt,
    st.ClosedAt,
    CONCAT(N'Synthetic support ticket ', n.n),
    SYSUTCDATETIME()
FROM #Nums n
CROSS APPLY
(
    SELECT
        DATEADD(DAY, -(n.n % 365), SYSUTCDATETIME()) AS OpenedAt,
        CASE
            WHEN n.n % 7 = 0 THEN 'Closed'
            WHEN n.n % 5 = 0 THEN 'Resolved'
            WHEN n.n % 3 = 0 THEN 'InProgress'
            ELSE 'Open'
        END AS StatusName
) st0
CROSS APPLY
(
    SELECT
        st0.StatusName,
        st0.OpenedAt,
        CASE
            WHEN st0.StatusName IN ('Closed', 'Resolved') THEN DATEADD(DAY, (n.n % 15) + 1, st0.OpenedAt)
            ELSE NULL
        END AS ClosedAt
) st
WHERE n.n <= 5000;

/* Required fraud scenarios */
DECLARE @LargeTxn TABLE (TransactionId BIGINT PRIMARY KEY);
DECLARE @GeoTxn TABLE (TransactionId BIGINT PRIMARY KEY);

;WITH TargetAccounts AS
(
    SELECT TOP (300)
        a.AccountId,
        a.CurrencyCode,
        ci.CountryId,
        br.CityId
    FROM bank.Accounts a
    JOIN bank.Branches br ON br.BranchId = a.BranchId
    JOIN bank.Cities ci ON ci.CityId = br.CityId
    WHERE a.AccountStatusId = 1
    ORDER BY a.AccountId
)
INSERT INTO bank.[Transactions]
(
    AccountId,
    TransactionTypeId,
    ChannelId,
    MerchantId,
    CounterpartyAccountId,
    Amount,
    CurrencyCode,
    TransactionDate,
    CountryId,
    CityId,
    TransactionStatus,
    Description,
    IsReversed,
    CreatedAt,
    UpdatedAt
)
OUTPUT inserted.TransactionId INTO @LargeTxn (TransactionId)
SELECT
    ta.AccountId,
    3,
    6,
    NULL,
    ((ta.AccountId + (v.Seq * 37)) % 25000) + 1,
    CAST(11000 + (ta.AccountId % 6000) + (v.Seq * 250) AS DECIMAL(19,2)),
    ta.CurrencyCode,
    DATEADD(MINUTE, v.Seq * 15, DATEADD(DAY, -(ta.AccountId % 45), SYSUTCDATETIME())),
    ta.CountryId,
    ta.CityId,
    'Posted',
    N'Fraud scenario: multiple large transactions',
    0,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM TargetAccounts ta
CROSS JOIN (VALUES (0), (1), (2)) v(Seq);

;WITH GeoTargets AS
(
    SELECT TOP (250)
        a.AccountId,
        a.CurrencyCode,
        ci.CountryId AS HomeCountryId,
        br.CityId AS HomeCityId,
        CASE WHEN ci.CountryId = 1 THEN 2 ELSE 1 END AS AltCountryId
    FROM bank.Accounts a
    JOIN bank.Branches br ON br.BranchId = a.BranchId
    JOIN bank.Cities ci ON ci.CityId = br.CityId
    WHERE a.AccountStatusId = 1
    ORDER BY a.AccountId DESC
)
INSERT INTO bank.[Transactions]
(
    AccountId,
    TransactionTypeId,
    ChannelId,
    MerchantId,
    CounterpartyAccountId,
    Amount,
    CurrencyCode,
    TransactionDate,
    CountryId,
    CityId,
    TransactionStatus,
    Description,
    IsReversed,
    CreatedAt,
    UpdatedAt
)
OUTPUT inserted.TransactionId INTO @GeoTxn (TransactionId)
SELECT
    gt.AccountId,
    4,
    5,
    ((gt.AccountId + v.Seq) % 500) + 1,
    NULL,
    CAST(250 + ((gt.AccountId + v.Seq) % 1750) AS DECIMAL(19,2)),
    gt.CurrencyCode,
    DATEADD(MINUTE, v.Seq * 7, DATEADD(DAY, -(gt.AccountId % 20), SYSUTCDATETIME())),
    CASE WHEN v.Seq = 0 THEN gt.HomeCountryId ELSE gt.AltCountryId END,
    CASE WHEN v.Seq = 0 THEN gt.HomeCityId ELSE alt.AltCityId END,
    'Posted',
    N'Fraud scenario: geo velocity',
    0,
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM GeoTargets gt
CROSS JOIN (VALUES (0), (1)) v(Seq)
OUTER APPLY
(
    SELECT TOP (1) c2.CityId AS AltCityId
    FROM bank.Cities c2
    WHERE c2.CountryId = gt.AltCountryId
    ORDER BY c2.CityId
) alt;

DECLARE @RuleLarge SMALLINT = (SELECT RuleId FROM bank.FraudRules WHERE RuleCode = 'LARGE_TXN_1H');
DECLARE @RuleGeo SMALLINT = (SELECT RuleId FROM bank.FraudRules WHERE RuleCode = 'GEO_VELOCITY_10M');
DECLARE @RuleCard SMALLINT = (SELECT RuleId FROM bank.FraudRules WHERE RuleCode = 'CARD_ANOMALY');
DECLARE @RuleManual SMALLINT = (SELECT RuleId FROM bank.FraudRules WHERE RuleCode = 'MANUAL_REVIEW');

INSERT INTO bank.FraudDetection
(
    RuleId,
    TransactionId,
    CardTransactionId,
    DetectionTime,
    RiskScore,
    FraudStatus,
    ReviewedByEmployeeId,
    ReviewNotes,
    CreatedAt,
    UpdatedAt
)
SELECT
    @RuleLarge,
    lt.TransactionId,
    NULL,
    DATEADD(MINUTE, 1, t.TransactionDate),
    CAST(90 + (lt.TransactionId % 8) AS DECIMAL(5,2)),
    'Open',
    NULL,
    N'Auto-detected: large transactions in less than one hour',
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM @LargeTxn lt
JOIN bank.[Transactions] t ON t.TransactionId = lt.TransactionId;

INSERT INTO bank.FraudDetection
(
    RuleId,
    TransactionId,
    CardTransactionId,
    DetectionTime,
    RiskScore,
    FraudStatus,
    ReviewedByEmployeeId,
    ReviewNotes,
    CreatedAt,
    UpdatedAt
)
SELECT
    @RuleGeo,
    gt.TransactionId,
    NULL,
    DATEADD(MINUTE, 1, t.TransactionDate),
    CAST(86 + (gt.TransactionId % 10) AS DECIMAL(5,2)),
    'Open',
    NULL,
    N'Auto-detected: cross-country velocity under 10 minutes',
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM @GeoTxn gt
JOIN bank.[Transactions] t ON t.TransactionId = gt.TransactionId;

INSERT INTO bank.FraudDetection
(
    RuleId,
    TransactionId,
    CardTransactionId,
    DetectionTime,
    RiskScore,
    FraudStatus,
    ReviewedByEmployeeId,
    ReviewNotes,
    CreatedAt,
    UpdatedAt
)
SELECT TOP (1200)
    @RuleCard,
    NULL,
    cct.CardTransactionId,
    DATEADD(MINUTE, 1, cct.TransactionDate),
    CAST(74 + (cct.CardTransactionId % 24) AS DECIMAL(5,2)),
    CASE WHEN cct.CardTransactionId % 9 = 0 THEN 'Investigating' ELSE 'Open' END,
    NULL,
    N'Auto-detected card anomaly',
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM bank.CreditCardTransactions cct
WHERE cct.IsInternational = 1
   OR cct.Amount > 7000
ORDER BY cct.Amount DESC, cct.TransactionDate DESC;

INSERT INTO bank.FraudDetection
(
    RuleId,
    TransactionId,
    CardTransactionId,
    DetectionTime,
    RiskScore,
    FraudStatus,
    ReviewedByEmployeeId,
    ReviewNotes,
    CreatedAt,
    UpdatedAt
)
SELECT TOP (200)
    @RuleManual,
    t.TransactionId,
    NULL,
    DATEADD(MINUTE, 2, t.TransactionDate),
    CAST(70 + (t.TransactionId % 20) AS DECIMAL(5,2)),
    'Investigating',
    ((t.TransactionId - 1) % 1200) + 1,
    N'Manual review queue',
    SYSUTCDATETIME(),
    SYSUTCDATETIME()
FROM bank.[Transactions] t
WHERE t.Amount > 15000
ORDER BY t.Amount DESC, t.TransactionDate DESC;

INSERT INTO bank.Alerts
(
    FraudCaseId,
    AlertType,
    Severity,
    AlertTime,
    IsAcknowledged,
    AcknowledgedByEmployeeId,
    AcknowledgedAt,
    CreatedAt
)
SELECT
    fd.FraudCaseId,
    CASE WHEN fd.TransactionId IS NOT NULL THEN 'TransactionFraud' ELSE 'CardFraud' END,
    CASE WHEN fd.RiskScore >= 90 THEN 'Critical' WHEN fd.RiskScore >= 80 THEN 'High' ELSE 'Medium' END,
    DATEADD(MINUTE, 2, fd.DetectionTime),
    CASE WHEN fd.FraudCaseId % 10 = 0 THEN 1 ELSE 0 END,
    CASE WHEN fd.FraudCaseId % 10 = 0 THEN ((fd.FraudCaseId - 1) % 1200) + 1 ELSE NULL END,
    CASE WHEN fd.FraudCaseId % 10 = 0 THEN DATEADD(MINUTE, 20, fd.DetectionTime) ELSE NULL END,
    SYSUTCDATETIME()
FROM bank.FraudDetection fd;

/* Validation queries */
PRINT 'Validation: Row counts';
SELECT 'Countries' AS TableName, COUNT(*) AS RowCount FROM bank.Countries
UNION ALL SELECT 'Cities', COUNT(*) FROM bank.Cities
UNION ALL SELECT 'Branches', COUNT(*) FROM bank.Branches
UNION ALL SELECT 'Employees', COUNT(*) FROM bank.Employees
UNION ALL SELECT 'Customers', COUNT(*) FROM bank.Customers
UNION ALL SELECT 'CustomerContacts', COUNT(*) FROM bank.CustomerContacts
UNION ALL SELECT 'Accounts', COUNT(*) FROM bank.Accounts
UNION ALL SELECT 'AccountHolders', COUNT(*) FROM bank.AccountHolders
UNION ALL SELECT 'Transactions', COUNT(*) FROM bank.[Transactions]
UNION ALL SELECT 'Cards', COUNT(*) FROM bank.Cards
UNION ALL SELECT 'CreditCardTransactions', COUNT(*) FROM bank.CreditCardTransactions
UNION ALL SELECT 'Loans', COUNT(*) FROM bank.Loans
UNION ALL SELECT 'LoanPaymentSchedule', COUNT(*) FROM bank.LoanPaymentSchedule
UNION ALL SELECT 'LoanPayments', COUNT(*) FROM bank.LoanPayments
UNION ALL SELECT 'FraudDetection', COUNT(*) FROM bank.FraudDetection
UNION ALL SELECT 'Alerts', COUNT(*) FROM bank.Alerts
UNION ALL SELECT 'DailyAccountSnapshot', COUNT(*) FROM bank.DailyAccountSnapshot
UNION ALL SELECT 'LoginEvents', COUNT(*) FROM bank.LoginEvents
ORDER BY TableName;

PRINT 'Validation: FK integrity checks (all should be 0)';
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
SELECT 'CardTx->Cards', COUNT(*)
FROM bank.CreditCardTransactions cct
LEFT JOIN bank.Cards c ON c.CardId = cct.CardId
WHERE c.CardId IS NULL
UNION ALL
SELECT 'Loans->Customers', COUNT(*)
FROM bank.Loans l
LEFT JOIN bank.Customers c ON c.CustomerId = l.CustomerId
WHERE c.CustomerId IS NULL
UNION ALL
SELECT 'FraudDetection->Transactions', COUNT(*)
FROM bank.FraudDetection fd
LEFT JOIN bank.[Transactions] t ON t.TransactionId = fd.TransactionId
WHERE fd.TransactionId IS NOT NULL AND t.TransactionId IS NULL
UNION ALL
SELECT 'FraudDetection->CardTx', COUNT(*)
FROM bank.FraudDetection fd
LEFT JOIN bank.CreditCardTransactions cct ON cct.CardTransactionId = fd.CardTransactionId
WHERE fd.CardTransactionId IS NOT NULL AND cct.CardTransactionId IS NULL;

PRINT 'Validation: Sample KPI outputs (top rows only)';

/* Top 3 customers by total balance */
SELECT TOP (3)
    c.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName,
    CAST(SUM(a.CurrentBalance * (ah.OwnershipPercent / 100.0)) AS DECIMAL(19,2)) AS TotalBalance
FROM bank.Customers c
JOIN bank.AccountHolders ah ON ah.CustomerId = c.CustomerId AND ah.EndDate IS NULL
JOIN bank.Accounts a ON a.AccountId = ah.AccountId
GROUP BY c.CustomerId, c.CustomerNumber, c.FirstName, c.LastName
ORDER BY TotalBalance DESC;

/* Customers with more than one active loan */
SELECT TOP (10)
    c.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName,
    COUNT(*) AS ActiveLoanCount
FROM bank.Loans l
JOIN bank.Customers c ON c.CustomerId = l.CustomerId
WHERE l.LoanStatus = 'Active'
GROUP BY c.CustomerId, c.CustomerNumber, c.FirstName, c.LastName
HAVING COUNT(*) > 1
ORDER BY ActiveLoanCount DESC, c.CustomerId;

/* Transactions flagged as fraudulent */
SELECT TOP (10)
    fd.FraudCaseId,
    fr.RuleCode,
    fd.TransactionId,
    fd.CardTransactionId,
    fd.RiskScore,
    fd.FraudStatus,
    fd.DetectionTime
FROM bank.FraudDetection fd
JOIN bank.FraudRules fr ON fr.RuleId = fd.RuleId
ORDER BY fd.DetectionTime DESC;

/* Total loan amount issued per branch */
SELECT TOP (10)
    b.BranchId,
    b.BranchCode,
    b.BranchName,
    CAST(SUM(l.PrincipalAmount) AS DECIMAL(19,2)) AS TotalLoanIssued
FROM bank.Loans l
JOIN bank.Branches b ON b.BranchId = l.BranchId
GROUP BY b.BranchId, b.BranchCode, b.BranchName
ORDER BY TotalLoanIssued DESC;

/* Multiple large transactions (> $10,000) within < 1 hour */
WITH LargeTx AS
(
    SELECT TransactionId, AccountId, TransactionDate, Amount
    FROM bank.[Transactions]
    WHERE Amount > 10000
      AND TransactionStatus = 'Posted'
),
Pairs AS
(
    SELECT
        lt1.AccountId,
        lt1.TransactionId AS TransactionId1,
        lt2.TransactionId AS TransactionId2,
        lt1.TransactionDate AS TxnTime1,
        lt2.TransactionDate AS TxnTime2,
        DATEDIFF(MINUTE, lt1.TransactionDate, lt2.TransactionDate) AS MinutesDiff
    FROM LargeTx lt1
    JOIN LargeTx lt2
        ON lt1.AccountId = lt2.AccountId
       AND lt1.TransactionId < lt2.TransactionId
       AND lt2.TransactionDate < DATEADD(HOUR, 1, lt1.TransactionDate)
       AND lt2.TransactionDate > lt1.TransactionDate
)
SELECT TOP (10) *
FROM Pairs
ORDER BY TxnTime1 DESC;

/* Transactions from different countries within 10 minutes */
WITH TxPerCustomer AS
(
    SELECT
        ah.CustomerId,
        t.TransactionId,
        t.TransactionDate,
        t.CountryId,
        LAG(t.TransactionId) OVER (PARTITION BY ah.CustomerId ORDER BY t.TransactionDate) AS PrevTransactionId,
        LAG(t.TransactionDate) OVER (PARTITION BY ah.CustomerId ORDER BY t.TransactionDate) AS PrevTransactionDate,
        LAG(t.CountryId) OVER (PARTITION BY ah.CustomerId ORDER BY t.TransactionDate) AS PrevCountryId
    FROM bank.[Transactions] t
    JOIN bank.AccountHolders ah
        ON ah.AccountId = t.AccountId
       AND ah.IsPrimary = 1
       AND ah.EndDate IS NULL
    WHERE t.TransactionStatus = 'Posted'
)
SELECT TOP (10)
    tx.CustomerId,
    tx.PrevTransactionId,
    tx.TransactionId,
    tx.PrevCountryId,
    tx.CountryId,
    DATEDIFF(MINUTE, tx.PrevTransactionDate, tx.TransactionDate) AS MinutesDiff,
    tx.PrevTransactionDate,
    tx.TransactionDate
FROM TxPerCustomer tx
WHERE tx.PrevCountryId IS NOT NULL
  AND tx.PrevCountryId <> tx.CountryId
  AND DATEDIFF(MINUTE, tx.PrevTransactionDate, tx.TransactionDate) <= 10
ORDER BY tx.TransactionDate DESC;
