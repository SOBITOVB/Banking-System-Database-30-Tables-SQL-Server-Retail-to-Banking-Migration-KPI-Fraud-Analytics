SET NOCOUNT ON;
GO

IF DB_ID(N'BankingSystem') IS NULL
BEGIN
    CREATE DATABASE BankingSystem;
END;
GO

USE BankingSystem;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'bank')
BEGIN
    EXEC(N'CREATE SCHEMA bank');
END;
GO

/* Drop in dependency-safe order */
DROP TABLE IF EXISTS bank.ServiceTickets;
DROP TABLE IF EXISTS bank.LoginEvents;
DROP TABLE IF EXISTS bank.DigitalDevices;
DROP TABLE IF EXISTS bank.DailyAccountSnapshot;
DROP TABLE IF EXISTS bank.ExchangeRates;
DROP TABLE IF EXISTS bank.Alerts;
DROP TABLE IF EXISTS bank.FraudDetection;
DROP TABLE IF EXISTS bank.FraudRules;
DROP TABLE IF EXISTS bank.LoanCollaterals;
DROP TABLE IF EXISTS bank.LoanPayments;
DROP TABLE IF EXISTS bank.LoanPaymentSchedule;
DROP TABLE IF EXISTS bank.Loans;
DROP TABLE IF EXISTS bank.LoanTypes;
DROP TABLE IF EXISTS bank.CreditCardTransactions;
DROP TABLE IF EXISTS bank.CreditCardAccounts;
DROP TABLE IF EXISTS bank.Cards;
DROP TABLE IF EXISTS bank.CardTypes;
DROP TABLE IF EXISTS bank.[Transactions];
DROP TABLE IF EXISTS bank.Merchants;
DROP TABLE IF EXISTS bank.MerchantCategories;
DROP TABLE IF EXISTS bank.ChannelTypes;
DROP TABLE IF EXISTS bank.TransactionTypes;
DROP TABLE IF EXISTS bank.AccountBeneficiaries;
DROP TABLE IF EXISTS bank.AccountHolders;
DROP TABLE IF EXISTS bank.Accounts;
DROP TABLE IF EXISTS bank.AccountStatus;
DROP TABLE IF EXISTS bank.AccountTypes;
DROP TABLE IF EXISTS bank.CustomerRiskProfileHistory;
DROP TABLE IF EXISTS bank.RiskProfiles;
DROP TABLE IF EXISTS bank.CustomerKYC;
DROP TABLE IF EXISTS bank.KYCStatus;
DROP TABLE IF EXISTS bank.CustomerEmployment;
DROP TABLE IF EXISTS bank.CustomerAddressHistory;
DROP TABLE IF EXISTS bank.CustomerContacts;
DROP TABLE IF EXISTS bank.Customers;
DROP TABLE IF EXISTS bank.CustomerSegments;
DROP TABLE IF EXISTS bank.Employees;
DROP TABLE IF EXISTS bank.Departments;
DROP TABLE IF EXISTS bank.Branches;
DROP TABLE IF EXISTS bank.Cities;
DROP TABLE IF EXISTS bank.Countries;
GO

CREATE TABLE bank.Countries
(
    CountryId       INT IDENTITY(1,1) NOT NULL,
    CountryCode     CHAR(2) NOT NULL,
    CountryName     NVARCHAR(100) NOT NULL,
    Region          NVARCHAR(50) NULL,
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Countries_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Countries PRIMARY KEY CLUSTERED (CountryId),
    CONSTRAINT UQ_Countries_CountryCode UNIQUE (CountryCode),
    CONSTRAINT UQ_Countries_CountryName UNIQUE (CountryName)
);
GO

CREATE TABLE bank.Cities
(
    CityId          INT IDENTITY(1,1) NOT NULL,
    CountryId       INT NOT NULL,
    CityName        NVARCHAR(100) NOT NULL,
    StateProvince   NVARCHAR(100) NULL,
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Cities_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Cities PRIMARY KEY CLUSTERED (CityId),
    CONSTRAINT UQ_Cities_Country_City_State UNIQUE (CountryId, CityName, StateProvince),
    CONSTRAINT FK_Cities_Countries FOREIGN KEY (CountryId) REFERENCES bank.Countries (CountryId)
);
GO

CREATE TABLE bank.Branches
(
    BranchId        INT IDENTITY(1,1) NOT NULL,
    BranchCode      VARCHAR(10) NOT NULL,
    BranchName      NVARCHAR(150) NOT NULL,
    CityId          INT NOT NULL,
    AddressLine1    NVARCHAR(200) NOT NULL,
    PhoneNumber     VARCHAR(25) NULL,
    OpenedDate      DATE NOT NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_Branches_IsActive DEFAULT (1),
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Branches_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Branches_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Branches PRIMARY KEY CLUSTERED (BranchId),
    CONSTRAINT UQ_Branches_BranchCode UNIQUE (BranchCode),
    CONSTRAINT FK_Branches_Cities FOREIGN KEY (CityId) REFERENCES bank.Cities (CityId)
);
GO

CREATE TABLE bank.Departments
(
    DepartmentId    TINYINT IDENTITY(1,1) NOT NULL,
    DepartmentName  NVARCHAR(100) NOT NULL,
    CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Departments_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Departments PRIMARY KEY CLUSTERED (DepartmentId),
    CONSTRAINT UQ_Departments_DepartmentName UNIQUE (DepartmentName)
);
GO

CREATE TABLE bank.Employees
(
    EmployeeId          INT IDENTITY(1,1) NOT NULL,
    BranchId            INT NOT NULL,
    DepartmentId        TINYINT NOT NULL,
    ManagerEmployeeId   INT NULL,
    FirstName           NVARCHAR(100) NOT NULL,
    LastName            NVARCHAR(100) NOT NULL,
    Email               NVARCHAR(200) NOT NULL,
    JobTitle            NVARCHAR(100) NOT NULL,
    HireDate            DATE NOT NULL,
    IsActive            BIT NOT NULL CONSTRAINT DF_Employees_IsActive DEFAULT (1),
    CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_Employees_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_Employees_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Employees PRIMARY KEY CLUSTERED (EmployeeId),
    CONSTRAINT UQ_Employees_Email UNIQUE (Email),
    CONSTRAINT FK_Employees_Branches FOREIGN KEY (BranchId) REFERENCES bank.Branches (BranchId),
    CONSTRAINT FK_Employees_Departments FOREIGN KEY (DepartmentId) REFERENCES bank.Departments (DepartmentId),
    CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerEmployeeId) REFERENCES bank.Employees (EmployeeId)
);
GO

CREATE TABLE bank.CustomerSegments
(
    SegmentId        TINYINT IDENTITY(1,1) NOT NULL,
    SegmentName      NVARCHAR(50) NOT NULL,
    Description      NVARCHAR(200) NULL,
    CreatedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerSegments_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerSegments PRIMARY KEY CLUSTERED (SegmentId),
    CONSTRAINT UQ_CustomerSegments_SegmentName UNIQUE (SegmentName)
);
GO

CREATE TABLE bank.Customers
(
    CustomerId        INT IDENTITY(1,1) NOT NULL,
    CustomerNumber    VARCHAR(20) NOT NULL,
    FirstName         NVARCHAR(100) NOT NULL,
    LastName          NVARCHAR(100) NOT NULL,
    DateOfBirth       DATE NOT NULL,
    Gender            CHAR(1) NULL,
    NationalId        VARCHAR(30) NOT NULL,
    TaxId             VARCHAR(30) NULL,
    SegmentId         TINYINT NOT NULL,
    HomeBranchId      INT NOT NULL,
    OnboardingDate    DATE NOT NULL,
    Status            VARCHAR(20) NOT NULL,
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerId),
    CONSTRAINT UQ_Customers_CustomerNumber UNIQUE (CustomerNumber),
    CONSTRAINT UQ_Customers_NationalId UNIQUE (NationalId),
    CONSTRAINT CK_Customers_Gender CHECK (Gender IN ('M', 'F', 'O') OR Gender IS NULL),
    CONSTRAINT CK_Customers_Status CHECK (Status IN ('Active', 'Inactive', 'Closed', 'Deceased')),
    CONSTRAINT FK_Customers_Segment FOREIGN KEY (SegmentId) REFERENCES bank.CustomerSegments (SegmentId),
    CONSTRAINT FK_Customers_HomeBranch FOREIGN KEY (HomeBranchId) REFERENCES bank.Branches (BranchId)
);
GO

CREATE TABLE bank.CustomerContacts
(
    ContactId         BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId        INT NOT NULL,
    ContactType       VARCHAR(20) NOT NULL,
    ContactValue      NVARCHAR(200) NOT NULL,
    IsPrimary         BIT NOT NULL CONSTRAINT DF_CustomerContacts_IsPrimary DEFAULT (0),
    VerifiedAt        DATETIME2(0) NULL,
    CreatedAt         DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerContacts_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerContacts PRIMARY KEY CLUSTERED (ContactId),
    CONSTRAINT UQ_CustomerContacts UNIQUE (CustomerId, ContactType, ContactValue),
    CONSTRAINT CK_CustomerContacts_Type CHECK (ContactType IN ('Email', 'Phone', 'SMS', 'Address', 'Other')),
    CONSTRAINT FK_CustomerContacts_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId)
);
GO

CREATE TABLE bank.CustomerAddressHistory
(
    AddressHistoryId   BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId         INT NOT NULL,
    AddressLine1       NVARCHAR(200) NOT NULL,
    CityId             INT NOT NULL,
    PostalCode         VARCHAR(20) NULL,
    CountryId          INT NOT NULL,
    ValidFrom          DATE NOT NULL,
    ValidTo            DATE NULL,
    IsCurrent          BIT NOT NULL CONSTRAINT DF_CustomerAddressHistory_IsCurrent DEFAULT (1),
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerAddressHistory_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerAddressHistory PRIMARY KEY CLUSTERED (AddressHistoryId),
    CONSTRAINT CK_CustomerAddressHistory_Dates CHECK (ValidTo IS NULL OR ValidTo >= ValidFrom),
    CONSTRAINT FK_CustomerAddressHistory_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_CustomerAddressHistory_Cities FOREIGN KEY (CityId) REFERENCES bank.Cities (CityId),
    CONSTRAINT FK_CustomerAddressHistory_Countries FOREIGN KEY (CountryId) REFERENCES bank.Countries (CountryId)
);
GO

CREATE TABLE bank.CustomerEmployment
(
    EmploymentId       BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId         INT NOT NULL,
    EmployerName       NVARCHAR(200) NOT NULL,
    Occupation         NVARCHAR(100) NOT NULL,
    AnnualIncome       DECIMAL(18,2) NOT NULL,
    EmploymentStatus   VARCHAR(20) NOT NULL,
    StartDate          DATE NOT NULL,
    EndDate            DATE NULL,
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerEmployment_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerEmployment PRIMARY KEY CLUSTERED (EmploymentId),
    CONSTRAINT CK_CustomerEmployment_Income CHECK (AnnualIncome >= 0),
    CONSTRAINT CK_CustomerEmployment_Status CHECK (EmploymentStatus IN ('Employed', 'SelfEmployed', 'Unemployed', 'Retired', 'Student')),
    CONSTRAINT CK_CustomerEmployment_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate),
    CONSTRAINT FK_CustomerEmployment_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId)
);
GO

CREATE TABLE bank.KYCStatus
(
    KYCStatusId        TINYINT IDENTITY(1,1) NOT NULL,
    StatusName         NVARCHAR(50) NOT NULL,
    Description        NVARCHAR(200) NULL,
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_KYCStatus_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_KYCStatus PRIMARY KEY CLUSTERED (KYCStatusId),
    CONSTRAINT UQ_KYCStatus_StatusName UNIQUE (StatusName)
);
GO

CREATE TABLE bank.CustomerKYC
(
    CustomerKYCId          BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId             INT NOT NULL,
    KYCStatusId            TINYINT NOT NULL,
    DocumentType           VARCHAR(30) NOT NULL,
    DocumentNumber         VARCHAR(50) NOT NULL,
    VerifiedByEmployeeId   INT NULL,
    VerificationDate       DATETIME2(0) NULL,
    ExpiryDate             DATE NULL,
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerKYC_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerKYC_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerKYC PRIMARY KEY CLUSTERED (CustomerKYCId),
    CONSTRAINT CK_CustomerKYC_DocType CHECK (DocumentType IN ('Passport', 'NationalId', 'DriverLicense', 'ResidencePermit')),
    CONSTRAINT FK_CustomerKYC_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_CustomerKYC_Status FOREIGN KEY (KYCStatusId) REFERENCES bank.KYCStatus (KYCStatusId),
    CONSTRAINT FK_CustomerKYC_Verifier FOREIGN KEY (VerifiedByEmployeeId) REFERENCES bank.Employees (EmployeeId)
);
GO

CREATE TABLE bank.RiskProfiles
(
    RiskProfileId      TINYINT IDENTITY(1,1) NOT NULL,
    RiskLevel          VARCHAR(20) NOT NULL,
    ScoreMin           INT NOT NULL,
    ScoreMax           INT NOT NULL,
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_RiskProfiles_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_RiskProfiles PRIMARY KEY CLUSTERED (RiskProfileId),
    CONSTRAINT UQ_RiskProfiles_RiskLevel UNIQUE (RiskLevel),
    CONSTRAINT CK_RiskProfiles_Range CHECK (ScoreMin >= 0 AND ScoreMax <= 1000 AND ScoreMax >= ScoreMin)
);
GO

CREATE TABLE bank.CustomerRiskProfileHistory
(
    RiskHistoryId      BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId         INT NOT NULL,
    RiskProfileId      TINYINT NOT NULL,
    EffectiveFrom      DATETIME2(0) NOT NULL,
    EffectiveTo        DATETIME2(0) NULL,
    Reason             NVARCHAR(200) NULL,
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_CustomerRiskProfileHistory_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CustomerRiskProfileHistory PRIMARY KEY CLUSTERED (RiskHistoryId),
    CONSTRAINT CK_CustomerRiskProfileHistory_Dates CHECK (EffectiveTo IS NULL OR EffectiveTo >= EffectiveFrom),
    CONSTRAINT FK_CustomerRiskProfileHistory_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_CustomerRiskProfileHistory_RiskProfile FOREIGN KEY (RiskProfileId) REFERENCES bank.RiskProfiles (RiskProfileId)
);
GO

CREATE TABLE bank.AccountTypes
(
    AccountTypeId      TINYINT IDENTITY(1,1) NOT NULL,
    AccountTypeName    NVARCHAR(50) NOT NULL,
    Description        NVARCHAR(200) NULL,
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_AccountTypes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AccountTypes PRIMARY KEY CLUSTERED (AccountTypeId),
    CONSTRAINT UQ_AccountTypes_AccountTypeName UNIQUE (AccountTypeName)
);
GO

CREATE TABLE bank.AccountStatus
(
    AccountStatusId    TINYINT IDENTITY(1,1) NOT NULL,
    StatusName         NVARCHAR(50) NOT NULL,
    Description        NVARCHAR(200) NULL,
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_AccountStatus_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AccountStatus PRIMARY KEY CLUSTERED (AccountStatusId),
    CONSTRAINT UQ_AccountStatus_StatusName UNIQUE (StatusName)
);
GO

CREATE TABLE bank.Accounts
(
    AccountId           INT IDENTITY(1,1) NOT NULL,
    AccountNumber       VARCHAR(20) NOT NULL,
    PrimaryCustomerId   INT NOT NULL,
    BranchId            INT NOT NULL,
    AccountTypeId       TINYINT NOT NULL,
    AccountStatusId     TINYINT NOT NULL,
    CurrencyCode        CHAR(3) NOT NULL,
    OpenedDate          DATE NOT NULL,
    ClosedDate          DATE NULL,
    CurrentBalance      DECIMAL(19,2) NOT NULL,
    AvailableBalance    DECIMAL(19,2) NOT NULL,
    OverdraftLimit      DECIMAL(19,2) NOT NULL CONSTRAINT DF_Accounts_OverdraftLimit DEFAULT (0),
    InterestRate        DECIMAL(5,2) NOT NULL CONSTRAINT DF_Accounts_InterestRate DEFAULT (0),
    CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_Accounts_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_Accounts_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Accounts PRIMARY KEY CLUSTERED (AccountId),
    CONSTRAINT UQ_Accounts_AccountNumber UNIQUE (AccountNumber),
    CONSTRAINT CK_Accounts_Dates CHECK (ClosedDate IS NULL OR ClosedDate >= OpenedDate),
    CONSTRAINT CK_Accounts_Balance CHECK (CurrentBalance >= -OverdraftLimit AND AvailableBalance >= -OverdraftLimit),
    CONSTRAINT FK_Accounts_Customers FOREIGN KEY (PrimaryCustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_Accounts_Branches FOREIGN KEY (BranchId) REFERENCES bank.Branches (BranchId),
    CONSTRAINT FK_Accounts_AccountTypes FOREIGN KEY (AccountTypeId) REFERENCES bank.AccountTypes (AccountTypeId),
    CONSTRAINT FK_Accounts_AccountStatus FOREIGN KEY (AccountStatusId) REFERENCES bank.AccountStatus (AccountStatusId)
);
GO

CREATE TABLE bank.AccountHolders
(
    AccountHolderId      BIGINT IDENTITY(1,1) NOT NULL,
    AccountId            INT NOT NULL,
    CustomerId           INT NOT NULL,
    HolderRole           VARCHAR(20) NOT NULL,
    OwnershipPercent     DECIMAL(5,2) NOT NULL,
    IsPrimary            BIT NOT NULL CONSTRAINT DF_AccountHolders_IsPrimary DEFAULT (0),
    StartDate            DATE NOT NULL,
    EndDate              DATE NULL,
    CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_AccountHolders_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AccountHolders PRIMARY KEY CLUSTERED (AccountHolderId),
    CONSTRAINT UQ_AccountHolders UNIQUE (AccountId, CustomerId, StartDate),
    CONSTRAINT CK_AccountHolders_Role CHECK (HolderRole IN ('Primary', 'Joint', 'Guardian', 'AuthorizedSigner')),
    CONSTRAINT CK_AccountHolders_Ownership CHECK (OwnershipPercent > 0 AND OwnershipPercent <= 100),
    CONSTRAINT CK_AccountHolders_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate),
    CONSTRAINT FK_AccountHolders_Accounts FOREIGN KEY (AccountId) REFERENCES bank.Accounts (AccountId),
    CONSTRAINT FK_AccountHolders_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId)
);
GO

CREATE TABLE bank.AccountBeneficiaries
(
    BeneficiaryId            BIGINT IDENTITY(1,1) NOT NULL,
    AccountId                INT NOT NULL,
    BeneficiaryCustomerId    INT NOT NULL,
    RelationshipType         VARCHAR(30) NOT NULL,
    IsActive                 BIT NOT NULL CONSTRAINT DF_AccountBeneficiaries_IsActive DEFAULT (1),
    CreatedAt                DATETIME2(0) NOT NULL CONSTRAINT DF_AccountBeneficiaries_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AccountBeneficiaries PRIMARY KEY CLUSTERED (BeneficiaryId),
    CONSTRAINT UQ_AccountBeneficiaries UNIQUE (AccountId, BeneficiaryCustomerId),
    CONSTRAINT FK_AccountBeneficiaries_Accounts FOREIGN KEY (AccountId) REFERENCES bank.Accounts (AccountId),
    CONSTRAINT FK_AccountBeneficiaries_Customers FOREIGN KEY (BeneficiaryCustomerId) REFERENCES bank.Customers (CustomerId)
);
GO

CREATE TABLE bank.TransactionTypes
(
    TransactionTypeId    TINYINT IDENTITY(1,1) NOT NULL,
    TypeName             NVARCHAR(50) NOT NULL,
    Description          NVARCHAR(200) NULL,
    CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_TransactionTypes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_TransactionTypes PRIMARY KEY CLUSTERED (TransactionTypeId),
    CONSTRAINT UQ_TransactionTypes_TypeName UNIQUE (TypeName)
);
GO

CREATE TABLE bank.ChannelTypes
(
    ChannelId            TINYINT IDENTITY(1,1) NOT NULL,
    ChannelName          NVARCHAR(50) NOT NULL,
    Description          NVARCHAR(200) NULL,
    CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_ChannelTypes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ChannelTypes PRIMARY KEY CLUSTERED (ChannelId),
    CONSTRAINT UQ_ChannelTypes_ChannelName UNIQUE (ChannelName)
);
GO

CREATE TABLE bank.MerchantCategories
(
    MerchantCategoryId   SMALLINT IDENTITY(1,1) NOT NULL,
    CategoryName         NVARCHAR(100) NOT NULL,
    Description          NVARCHAR(200) NULL,
    CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_MerchantCategories_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_MerchantCategories PRIMARY KEY CLUSTERED (MerchantCategoryId),
    CONSTRAINT UQ_MerchantCategories_CategoryName UNIQUE (CategoryName)
);
GO

CREATE TABLE bank.Merchants
(
    MerchantId           INT IDENTITY(1,1) NOT NULL,
    MerchantName         NVARCHAR(200) NOT NULL,
    MerchantCategoryId   SMALLINT NOT NULL,
    CityId               INT NOT NULL,
    CountryId            INT NOT NULL,
    IsHighRisk           BIT NOT NULL CONSTRAINT DF_Merchants_IsHighRisk DEFAULT (0),
    CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_Merchants_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Merchants PRIMARY KEY CLUSTERED (MerchantId),
    CONSTRAINT FK_Merchants_MerchantCategories FOREIGN KEY (MerchantCategoryId) REFERENCES bank.MerchantCategories (MerchantCategoryId),
    CONSTRAINT FK_Merchants_Cities FOREIGN KEY (CityId) REFERENCES bank.Cities (CityId),
    CONSTRAINT FK_Merchants_Countries FOREIGN KEY (CountryId) REFERENCES bank.Countries (CountryId)
);
GO

CREATE TABLE bank.[Transactions]
(
    TransactionId         BIGINT IDENTITY(1,1) NOT NULL,
    AccountId             INT NOT NULL,
    TransactionTypeId     TINYINT NOT NULL,
    ChannelId             TINYINT NOT NULL,
    MerchantId            INT NULL,
    CounterpartyAccountId INT NULL,
    Amount                DECIMAL(19,2) NOT NULL,
    CurrencyCode          CHAR(3) NOT NULL,
    TransactionDate       DATETIME2(0) NOT NULL,
    CountryId             INT NOT NULL,
    CityId                INT NULL,
    TransactionStatus     VARCHAR(20) NOT NULL,
    Description           NVARCHAR(200) NULL,
    IsReversed            BIT NOT NULL CONSTRAINT DF_Transactions_IsReversed DEFAULT (0),
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Transactions_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Transactions_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED (TransactionId),
    CONSTRAINT CK_Transactions_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Transactions_Status CHECK (TransactionStatus IN ('Posted', 'Pending', 'Declined', 'Reversed')),
    CONSTRAINT FK_Transactions_Accounts FOREIGN KEY (AccountId) REFERENCES bank.Accounts (AccountId),
    CONSTRAINT FK_Transactions_TransactionTypes FOREIGN KEY (TransactionTypeId) REFERENCES bank.TransactionTypes (TransactionTypeId),
    CONSTRAINT FK_Transactions_ChannelTypes FOREIGN KEY (ChannelId) REFERENCES bank.ChannelTypes (ChannelId),
    CONSTRAINT FK_Transactions_Merchants FOREIGN KEY (MerchantId) REFERENCES bank.Merchants (MerchantId),
    CONSTRAINT FK_Transactions_Counterparty FOREIGN KEY (CounterpartyAccountId) REFERENCES bank.Accounts (AccountId),
    CONSTRAINT FK_Transactions_Countries FOREIGN KEY (CountryId) REFERENCES bank.Countries (CountryId),
    CONSTRAINT FK_Transactions_Cities FOREIGN KEY (CityId) REFERENCES bank.Cities (CityId)
);
GO

CREATE TABLE bank.CardTypes
(
    CardTypeId            TINYINT IDENTITY(1,1) NOT NULL,
    CardTypeName          NVARCHAR(50) NOT NULL,
    IsCredit              BIT NOT NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_CardTypes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CardTypes PRIMARY KEY CLUSTERED (CardTypeId),
    CONSTRAINT UQ_CardTypes_CardTypeName UNIQUE (CardTypeName)
);
GO

CREATE TABLE bank.Cards
(
    CardId                BIGINT IDENTITY(1,1) NOT NULL,
    AccountId             INT NOT NULL,
    CustomerId            INT NOT NULL,
    CardTypeId            TINYINT NOT NULL,
    CardNumber            CHAR(16) NOT NULL,
    MaskedCardNumber      VARCHAR(19) NOT NULL,
    CVVToken              VARCHAR(100) NOT NULL,
    ExpiryMonth           TINYINT NOT NULL,
    ExpiryYear            SMALLINT NOT NULL,
    IssuedDate            DATE NOT NULL,
    DailyLimit            DECIMAL(19,2) NOT NULL,
    IsActive              BIT NOT NULL CONSTRAINT DF_Cards_IsActive DEFAULT (1),
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Cards_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Cards_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Cards PRIMARY KEY CLUSTERED (CardId),
    CONSTRAINT UQ_Cards_CardNumber UNIQUE (CardNumber),
    CONSTRAINT CK_Cards_ExpiryMonth CHECK (ExpiryMonth BETWEEN 1 AND 12),
    CONSTRAINT CK_Cards_DailyLimit CHECK (DailyLimit > 0),
    CONSTRAINT FK_Cards_Accounts FOREIGN KEY (AccountId) REFERENCES bank.Accounts (AccountId),
    CONSTRAINT FK_Cards_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_Cards_CardTypes FOREIGN KEY (CardTypeId) REFERENCES bank.CardTypes (CardTypeId)
);
GO

CREATE TABLE bank.CreditCardAccounts
(
    CreditCardAccountId   BIGINT IDENTITY(1,1) NOT NULL,
    CardId                BIGINT NOT NULL,
    CreditLimit           DECIMAL(19,2) NOT NULL,
    AvailableCredit       DECIMAL(19,2) NOT NULL,
    APR                   DECIMAL(5,2) NOT NULL,
    BillingCycleDay       TINYINT NOT NULL,
    CurrentDueAmount      DECIMAL(19,2) NOT NULL CONSTRAINT DF_CreditCardAccounts_CurrentDueAmount DEFAULT (0),
    LastStatementDate     DATE NULL,
    PaymentDueDate        DATE NULL,
    Status                VARCHAR(20) NOT NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_CreditCardAccounts_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_CreditCardAccounts_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CreditCardAccounts PRIMARY KEY CLUSTERED (CreditCardAccountId),
    CONSTRAINT UQ_CreditCardAccounts_CardId UNIQUE (CardId),
    CONSTRAINT CK_CreditCardAccounts_Limits CHECK (CreditLimit > 0 AND AvailableCredit >= 0 AND AvailableCredit <= CreditLimit),
    CONSTRAINT CK_CreditCardAccounts_APR CHECK (APR >= 0 AND APR <= 99.99),
    CONSTRAINT CK_CreditCardAccounts_BillingCycle CHECK (BillingCycleDay BETWEEN 1 AND 28),
    CONSTRAINT CK_CreditCardAccounts_Status CHECK (Status IN ('Active', 'Blocked', 'Closed')),
    CONSTRAINT FK_CreditCardAccounts_Cards FOREIGN KEY (CardId) REFERENCES bank.Cards (CardId)
);
GO

CREATE TABLE bank.CreditCardTransactions
(
    CardTransactionId      BIGINT IDENTITY(1,1) NOT NULL,
    CardId                 BIGINT NOT NULL,
    MerchantId             INT NOT NULL,
    ChannelId              TINYINT NOT NULL,
    Amount                 DECIMAL(19,2) NOT NULL,
    CurrencyCode           CHAR(3) NOT NULL,
    TransactionDate        DATETIME2(0) NOT NULL,
    CountryId              INT NOT NULL,
    CityId                 INT NULL,
    IsCardPresent          BIT NOT NULL,
    IsInternational        BIT NOT NULL CONSTRAINT DF_CreditCardTransactions_IsInternational DEFAULT (0),
    TransactionStatus      VARCHAR(20) NOT NULL,
    AuthCode               VARCHAR(20) NOT NULL,
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_CreditCardTransactions_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_CreditCardTransactions_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CreditCardTransactions PRIMARY KEY CLUSTERED (CardTransactionId),
    CONSTRAINT UQ_CreditCardTransactions_AuthCode UNIQUE (AuthCode),
    CONSTRAINT CK_CreditCardTransactions_Amount CHECK (Amount > 0),
    CONSTRAINT CK_CreditCardTransactions_Status CHECK (TransactionStatus IN ('Approved', 'Declined', 'Reversed')),
    CONSTRAINT FK_CreditCardTransactions_Cards FOREIGN KEY (CardId) REFERENCES bank.Cards (CardId),
    CONSTRAINT FK_CreditCardTransactions_Merchants FOREIGN KEY (MerchantId) REFERENCES bank.Merchants (MerchantId),
    CONSTRAINT FK_CreditCardTransactions_ChannelTypes FOREIGN KEY (ChannelId) REFERENCES bank.ChannelTypes (ChannelId),
    CONSTRAINT FK_CreditCardTransactions_Countries FOREIGN KEY (CountryId) REFERENCES bank.Countries (CountryId),
    CONSTRAINT FK_CreditCardTransactions_Cities FOREIGN KEY (CityId) REFERENCES bank.Cities (CityId)
);
GO

CREATE TABLE bank.LoanTypes
(
    LoanTypeId            TINYINT IDENTITY(1,1) NOT NULL,
    LoanTypeName          NVARCHAR(50) NOT NULL,
    Description           NVARCHAR(200) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_LoanTypes_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LoanTypes PRIMARY KEY CLUSTERED (LoanTypeId),
    CONSTRAINT UQ_LoanTypes_LoanTypeName UNIQUE (LoanTypeName)
);
GO

CREATE TABLE bank.Loans
(
    LoanId                INT IDENTITY(1,1) NOT NULL,
    CustomerId            INT NOT NULL,
    BranchId              INT NOT NULL,
    LoanTypeId            TINYINT NOT NULL,
    PrincipalAmount       DECIMAL(19,2) NOT NULL,
    InterestRate          DECIMAL(5,2) NOT NULL,
    TermMonths            SMALLINT NOT NULL,
    StartDate             DATE NOT NULL,
    MaturityDate          DATE NOT NULL,
    LoanStatus            VARCHAR(20) NOT NULL,
    OutstandingPrincipal  DECIMAL(19,2) NOT NULL,
    MonthlyInstallment    DECIMAL(19,2) NOT NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Loans_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_Loans_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Loans PRIMARY KEY CLUSTERED (LoanId),
    CONSTRAINT CK_Loans_Principal CHECK (PrincipalAmount > 0),
    CONSTRAINT CK_Loans_Interest CHECK (InterestRate >= 0 AND InterestRate <= 100),
    CONSTRAINT CK_Loans_Term CHECK (TermMonths > 0),
    CONSTRAINT CK_Loans_Dates CHECK (MaturityDate >= StartDate),
    CONSTRAINT CK_Loans_Status CHECK (LoanStatus IN ('Active', 'Closed', 'Delinquent', 'ChargedOff')),
    CONSTRAINT CK_Loans_Outstanding CHECK (OutstandingPrincipal >= 0),
    CONSTRAINT FK_Loans_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_Loans_Branches FOREIGN KEY (BranchId) REFERENCES bank.Branches (BranchId),
    CONSTRAINT FK_Loans_LoanTypes FOREIGN KEY (LoanTypeId) REFERENCES bank.LoanTypes (LoanTypeId)
);
GO

CREATE TABLE bank.LoanPaymentSchedule
(
    ScheduleId            BIGINT IDENTITY(1,1) NOT NULL,
    LoanId                INT NOT NULL,
    InstallmentNo         INT NOT NULL,
    DueDate               DATE NOT NULL,
    DueAmount             DECIMAL(19,2) NOT NULL,
    PrincipalComponent    DECIMAL(19,2) NOT NULL,
    InterestComponent     DECIMAL(19,2) NOT NULL,
    ScheduleStatus        VARCHAR(20) NOT NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_LoanPaymentSchedule_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LoanPaymentSchedule PRIMARY KEY CLUSTERED (ScheduleId),
    CONSTRAINT UQ_LoanPaymentSchedule UNIQUE (LoanId, InstallmentNo),
    CONSTRAINT CK_LoanPaymentSchedule_Amounts CHECK (DueAmount > 0 AND PrincipalComponent >= 0 AND InterestComponent >= 0),
    CONSTRAINT CK_LoanPaymentSchedule_Status CHECK (ScheduleStatus IN ('Planned', 'Due', 'Paid', 'Overdue')),
    CONSTRAINT FK_LoanPaymentSchedule_Loans FOREIGN KEY (LoanId) REFERENCES bank.Loans (LoanId)
);
GO

CREATE TABLE bank.LoanPayments
(
    LoanPaymentId         BIGINT IDENTITY(1,1) NOT NULL,
    LoanId                INT NOT NULL,
    ScheduleId            BIGINT NULL,
    PaymentDate           DATE NOT NULL,
    AmountPaid            DECIMAL(19,2) NOT NULL,
    PaymentChannelId      TINYINT NULL,
    PaymentStatus         VARCHAR(20) NOT NULL,
    ReferenceNo           VARCHAR(30) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_LoanPayments_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LoanPayments PRIMARY KEY CLUSTERED (LoanPaymentId),
    CONSTRAINT UQ_LoanPayments_ReferenceNo UNIQUE (ReferenceNo),
    CONSTRAINT CK_LoanPayments_Amount CHECK (AmountPaid > 0),
    CONSTRAINT CK_LoanPayments_Status CHECK (PaymentStatus IN ('Completed', 'Pending', 'Failed', 'Partial')),
    CONSTRAINT FK_LoanPayments_Loans FOREIGN KEY (LoanId) REFERENCES bank.Loans (LoanId),
    CONSTRAINT FK_LoanPayments_Schedule FOREIGN KEY (ScheduleId) REFERENCES bank.LoanPaymentSchedule (ScheduleId),
    CONSTRAINT FK_LoanPayments_Channel FOREIGN KEY (PaymentChannelId) REFERENCES bank.ChannelTypes (ChannelId)
);
GO

CREATE TABLE bank.LoanCollaterals
(
    CollateralId          BIGINT IDENTITY(1,1) NOT NULL,
    LoanId                INT NOT NULL,
    CollateralType        VARCHAR(40) NOT NULL,
    EstimatedValue        DECIMAL(19,2) NOT NULL,
    RegisteredDate        DATE NOT NULL,
    Description           NVARCHAR(200) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_LoanCollaterals_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LoanCollaterals PRIMARY KEY CLUSTERED (CollateralId),
    CONSTRAINT CK_LoanCollaterals_Value CHECK (EstimatedValue > 0),
    CONSTRAINT FK_LoanCollaterals_Loans FOREIGN KEY (LoanId) REFERENCES bank.Loans (LoanId)
);
GO

CREATE TABLE bank.FraudRules
(
    RuleId                SMALLINT IDENTITY(1,1) NOT NULL,
    RuleCode              VARCHAR(30) NOT NULL,
    RuleName              NVARCHAR(150) NOT NULL,
    RuleDescription       NVARCHAR(500) NOT NULL,
    IsActive              BIT NOT NULL CONSTRAINT DF_FraudRules_IsActive DEFAULT (1),
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_FraudRules_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_FraudRules PRIMARY KEY CLUSTERED (RuleId),
    CONSTRAINT UQ_FraudRules_RuleCode UNIQUE (RuleCode)
);
GO

CREATE TABLE bank.FraudDetection
(
    FraudCaseId           BIGINT IDENTITY(1,1) NOT NULL,
    RuleId                SMALLINT NOT NULL,
    TransactionId         BIGINT NULL,
    CardTransactionId     BIGINT NULL,
    DetectionTime         DATETIME2(0) NOT NULL,
    RiskScore             DECIMAL(5,2) NOT NULL,
    FraudStatus           VARCHAR(20) NOT NULL,
    ReviewedByEmployeeId  INT NULL,
    ReviewNotes           NVARCHAR(300) NULL,
    CreatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_FraudDetection_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2(0) NOT NULL CONSTRAINT DF_FraudDetection_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_FraudDetection PRIMARY KEY CLUSTERED (FraudCaseId),
    CONSTRAINT CK_FraudDetection_Score CHECK (RiskScore BETWEEN 0 AND 100),
    CONSTRAINT CK_FraudDetection_Status CHECK (FraudStatus IN ('Open', 'Investigating', 'Confirmed', 'FalsePositive', 'Closed')),
    CONSTRAINT CK_FraudDetection_Source CHECK (
        (TransactionId IS NOT NULL AND CardTransactionId IS NULL)
        OR (TransactionId IS NULL AND CardTransactionId IS NOT NULL)
    ),
    CONSTRAINT FK_FraudDetection_Rules FOREIGN KEY (RuleId) REFERENCES bank.FraudRules (RuleId),
    CONSTRAINT FK_FraudDetection_Transactions FOREIGN KEY (TransactionId) REFERENCES bank.[Transactions] (TransactionId),
    CONSTRAINT FK_FraudDetection_CardTransactions FOREIGN KEY (CardTransactionId) REFERENCES bank.CreditCardTransactions (CardTransactionId),
    CONSTRAINT FK_FraudDetection_Employees FOREIGN KEY (ReviewedByEmployeeId) REFERENCES bank.Employees (EmployeeId)
);
GO

CREATE TABLE bank.Alerts
(
    AlertId                   BIGINT IDENTITY(1,1) NOT NULL,
    FraudCaseId               BIGINT NOT NULL,
    AlertType                 VARCHAR(50) NOT NULL,
    Severity                  VARCHAR(10) NOT NULL,
    AlertTime                 DATETIME2(0) NOT NULL CONSTRAINT DF_Alerts_AlertTime DEFAULT SYSUTCDATETIME(),
    IsAcknowledged            BIT NOT NULL CONSTRAINT DF_Alerts_IsAcknowledged DEFAULT (0),
    AcknowledgedByEmployeeId  INT NULL,
    AcknowledgedAt            DATETIME2(0) NULL,
    CreatedAt                 DATETIME2(0) NOT NULL CONSTRAINT DF_Alerts_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Alerts PRIMARY KEY CLUSTERED (AlertId),
    CONSTRAINT CK_Alerts_Severity CHECK (Severity IN ('Low', 'Medium', 'High', 'Critical')),
    CONSTRAINT CK_Alerts_Ack CHECK (
        (IsAcknowledged = 0 AND AcknowledgedAt IS NULL)
        OR (IsAcknowledged = 1 AND AcknowledgedAt IS NOT NULL)
    ),
    CONSTRAINT FK_Alerts_FraudDetection FOREIGN KEY (FraudCaseId) REFERENCES bank.FraudDetection (FraudCaseId),
    CONSTRAINT FK_Alerts_AcknowledgedBy FOREIGN KEY (AcknowledgedByEmployeeId) REFERENCES bank.Employees (EmployeeId)
);
GO

CREATE TABLE bank.ExchangeRates
(
    RateId                 BIGINT IDENTITY(1,1) NOT NULL,
    RateDate               DATE NOT NULL,
    FromCurrency           CHAR(3) NOT NULL,
    ToCurrency             CHAR(3) NOT NULL,
    Rate                   DECIMAL(18,8) NOT NULL,
    SourceSystem           VARCHAR(50) NOT NULL,
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ExchangeRates_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ExchangeRates PRIMARY KEY CLUSTERED (RateId),
    CONSTRAINT UQ_ExchangeRates UNIQUE (RateDate, FromCurrency, ToCurrency),
    CONSTRAINT CK_ExchangeRates_Rate CHECK (Rate > 0)
);
GO

CREATE TABLE bank.DailyAccountSnapshot
(
    SnapshotId             BIGINT IDENTITY(1,1) NOT NULL,
    AccountId              INT NOT NULL,
    SnapshotDate           DATE NOT NULL,
    EndOfDayBalance        DECIMAL(19,2) NOT NULL,
    AvailableBalance       DECIMAL(19,2) NOT NULL,
    DebitTurnover          DECIMAL(19,2) NOT NULL,
    CreditTurnover         DECIMAL(19,2) NOT NULL,
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_DailyAccountSnapshot_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_DailyAccountSnapshot PRIMARY KEY CLUSTERED (SnapshotId),
    CONSTRAINT UQ_DailyAccountSnapshot UNIQUE (AccountId, SnapshotDate),
    CONSTRAINT FK_DailyAccountSnapshot_Accounts FOREIGN KEY (AccountId) REFERENCES bank.Accounts (AccountId)
);
GO

CREATE TABLE bank.DigitalDevices
(
    DeviceId               BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId             INT NOT NULL,
    DeviceFingerprint      VARCHAR(100) NOT NULL,
    DeviceType             VARCHAR(20) NOT NULL,
    FirstSeenAt            DATETIME2(0) NOT NULL,
    LastSeenAt             DATETIME2(0) NOT NULL,
    IsTrusted              BIT NOT NULL CONSTRAINT DF_DigitalDevices_IsTrusted DEFAULT (0),
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_DigitalDevices_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_DigitalDevices PRIMARY KEY CLUSTERED (DeviceId),
    CONSTRAINT UQ_DigitalDevices_DeviceFingerprint UNIQUE (DeviceFingerprint),
    CONSTRAINT CK_DigitalDevices_Type CHECK (DeviceType IN ('Mobile', 'Desktop', 'Tablet', 'ATM', 'POS')),
    CONSTRAINT CK_DigitalDevices_Seen CHECK (LastSeenAt >= FirstSeenAt),
    CONSTRAINT FK_DigitalDevices_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId)
);
GO

CREATE TABLE bank.LoginEvents
(
    LoginEventId           BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId             INT NOT NULL,
    DeviceId               BIGINT NULL,
    ChannelId              TINYINT NOT NULL,
    LoginTime              DATETIME2(0) NOT NULL,
    CountryId              INT NOT NULL,
    CityId                 INT NULL,
    Success                BIT NOT NULL,
    IPAddress              VARCHAR(45) NOT NULL,
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_LoginEvents_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LoginEvents PRIMARY KEY CLUSTERED (LoginEventId),
    CONSTRAINT FK_LoginEvents_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_LoginEvents_Devices FOREIGN KEY (DeviceId) REFERENCES bank.DigitalDevices (DeviceId),
    CONSTRAINT FK_LoginEvents_ChannelTypes FOREIGN KEY (ChannelId) REFERENCES bank.ChannelTypes (ChannelId),
    CONSTRAINT FK_LoginEvents_Countries FOREIGN KEY (CountryId) REFERENCES bank.Countries (CountryId),
    CONSTRAINT FK_LoginEvents_Cities FOREIGN KEY (CityId) REFERENCES bank.Cities (CityId)
);
GO

CREATE TABLE bank.ServiceTickets
(
    TicketId               BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId             INT NOT NULL,
    RelatedAccountId       INT NULL,
    RelatedLoanId          INT NULL,
    CreatedByEmployeeId    INT NULL,
    TicketType             VARCHAR(30) NOT NULL,
    Priority               VARCHAR(10) NOT NULL,
    Status                 VARCHAR(20) NOT NULL,
    OpenedAt               DATETIME2(0) NOT NULL,
    ClosedAt               DATETIME2(0) NULL,
    Summary                NVARCHAR(200) NOT NULL,
    CreatedAt              DATETIME2(0) NOT NULL CONSTRAINT DF_ServiceTickets_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ServiceTickets PRIMARY KEY CLUSTERED (TicketId),
    CONSTRAINT CK_ServiceTickets_Priority CHECK (Priority IN ('Low', 'Medium', 'High', 'Critical')),
    CONSTRAINT CK_ServiceTickets_Status CHECK (Status IN ('Open', 'InProgress', 'Resolved', 'Closed')),
    CONSTRAINT CK_ServiceTickets_Dates CHECK (ClosedAt IS NULL OR ClosedAt >= OpenedAt),
    CONSTRAINT FK_ServiceTickets_Customers FOREIGN KEY (CustomerId) REFERENCES bank.Customers (CustomerId),
    CONSTRAINT FK_ServiceTickets_Accounts FOREIGN KEY (RelatedAccountId) REFERENCES bank.Accounts (AccountId),
    CONSTRAINT FK_ServiceTickets_Loans FOREIGN KEY (RelatedLoanId) REFERENCES bank.Loans (LoanId),
    CONSTRAINT FK_ServiceTickets_Employees FOREIGN KEY (CreatedByEmployeeId) REFERENCES bank.Employees (EmployeeId)
);
GO

/* FK and analytics helper indexes */
CREATE INDEX IX_Cities_CountryId ON bank.Cities (CountryId);
CREATE INDEX IX_Branches_CityId ON bank.Branches (CityId);
CREATE INDEX IX_Employees_BranchId ON bank.Employees (BranchId);
CREATE INDEX IX_Employees_DepartmentId ON bank.Employees (DepartmentId);
CREATE INDEX IX_Customers_HomeBranchId ON bank.Customers (HomeBranchId);
CREATE INDEX IX_Customers_SegmentId ON bank.Customers (SegmentId);
CREATE INDEX IX_Customers_Status ON bank.Customers (Status);
CREATE INDEX IX_CustomerContacts_CustomerId ON bank.CustomerContacts (CustomerId);
CREATE INDEX IX_CustomerAddressHistory_CustomerId ON bank.CustomerAddressHistory (CustomerId);
CREATE INDEX IX_CustomerAddressHistory_CityId ON bank.CustomerAddressHistory (CityId);
CREATE INDEX IX_CustomerEmployment_CustomerId ON bank.CustomerEmployment (CustomerId);
CREATE INDEX IX_CustomerKYC_CustomerId ON bank.CustomerKYC (CustomerId);
CREATE INDEX IX_CustomerKYC_StatusId ON bank.CustomerKYC (KYCStatusId);
CREATE INDEX IX_CustomerRiskProfileHistory_CustomerId ON bank.CustomerRiskProfileHistory (CustomerId);
CREATE INDEX IX_Accounts_PrimaryCustomerId ON bank.Accounts (PrimaryCustomerId);
CREATE INDEX IX_Accounts_BranchId ON bank.Accounts (BranchId);
CREATE INDEX IX_Accounts_StatusId ON bank.Accounts (AccountStatusId);
CREATE INDEX IX_Accounts_Customer_Status ON bank.Accounts (PrimaryCustomerId, AccountStatusId);
CREATE INDEX IX_AccountHolders_AccountId ON bank.AccountHolders (AccountId);
CREATE INDEX IX_AccountHolders_CustomerId ON bank.AccountHolders (CustomerId);
CREATE INDEX IX_AccountBeneficiaries_AccountId ON bank.AccountBeneficiaries (AccountId);
CREATE INDEX IX_Transactions_AccountId ON bank.[Transactions] (AccountId);
CREATE INDEX IX_Transactions_TransactionDate ON bank.[Transactions] (TransactionDate);
CREATE INDEX IX_Transactions_CountryId ON bank.[Transactions] (CountryId);
CREATE INDEX IX_Transactions_Amount ON bank.[Transactions] (Amount);
CREATE INDEX IX_Transactions_Status ON bank.[Transactions] (TransactionStatus);
CREATE INDEX IX_Transactions_Account_Date ON bank.[Transactions] (AccountId, TransactionDate);
CREATE INDEX IX_Cards_AccountId ON bank.Cards (AccountId);
CREATE INDEX IX_Cards_CustomerId ON bank.Cards (CustomerId);
CREATE INDEX IX_CreditCardAccounts_CardId ON bank.CreditCardAccounts (CardId);
CREATE INDEX IX_CreditCardTransactions_CardId ON bank.CreditCardTransactions (CardId);
CREATE INDEX IX_CreditCardTransactions_Date ON bank.CreditCardTransactions (TransactionDate);
CREATE INDEX IX_CreditCardTransactions_Country ON bank.CreditCardTransactions (CountryId);
CREATE INDEX IX_Loans_CustomerId ON bank.Loans (CustomerId);
CREATE INDEX IX_Loans_BranchId ON bank.Loans (BranchId);
CREATE INDEX IX_Loans_Status ON bank.Loans (LoanStatus);
CREATE INDEX IX_Loans_StartDate ON bank.Loans (StartDate);
CREATE INDEX IX_LoanPaymentSchedule_LoanId ON bank.LoanPaymentSchedule (LoanId);
CREATE INDEX IX_LoanPayments_LoanId ON bank.LoanPayments (LoanId);
CREATE INDEX IX_LoanPayments_ScheduleId ON bank.LoanPayments (ScheduleId);
CREATE INDEX IX_LoanCollaterals_LoanId ON bank.LoanCollaterals (LoanId);
CREATE INDEX IX_FraudDetection_RuleId ON bank.FraudDetection (RuleId);
CREATE INDEX IX_FraudDetection_TransactionId ON bank.FraudDetection (TransactionId);
CREATE INDEX IX_FraudDetection_CardTransactionId ON bank.FraudDetection (CardTransactionId);
CREATE INDEX IX_FraudDetection_Status ON bank.FraudDetection (FraudStatus);
CREATE INDEX IX_Alerts_FraudCaseId ON bank.Alerts (FraudCaseId);
CREATE INDEX IX_DailyAccountSnapshot_AccountDate ON bank.DailyAccountSnapshot (AccountId, SnapshotDate);
CREATE INDEX IX_DigitalDevices_CustomerId ON bank.DigitalDevices (CustomerId);
CREATE INDEX IX_LoginEvents_CustomerTime ON bank.LoginEvents (CustomerId, LoginTime);
CREATE INDEX IX_ServiceTickets_CustomerId ON bank.ServiceTickets (CustomerId);
CREATE INDEX IX_ServiceTickets_Status ON bank.ServiceTickets (Status);
GO
