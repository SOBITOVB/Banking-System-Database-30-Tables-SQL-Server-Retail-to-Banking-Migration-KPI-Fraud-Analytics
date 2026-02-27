SET NOCOUNT ON;
GO

USE BankingSystem;
GO

/* KPI 1: Top 3 customers by total balance across all accounts */
SELECT TOP (3)
    c.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName,
    CAST(SUM(a.CurrentBalance * (ah.OwnershipPercent / 100.0)) AS DECIMAL(19,2)) AS TotalBalance
FROM bank.Customers c
JOIN bank.AccountHolders ah
    ON ah.CustomerId = c.CustomerId
   AND ah.EndDate IS NULL
JOIN bank.Accounts a
    ON a.AccountId = ah.AccountId
GROUP BY
    c.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName
ORDER BY TotalBalance DESC;

/* KPI 2: Customers with more than one active loan */
SELECT
    c.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName,
    COUNT(*) AS ActiveLoanCount,
    CAST(SUM(l.OutstandingPrincipal) AS DECIMAL(19,2)) AS TotalOutstandingPrincipal
FROM bank.Loans l
JOIN bank.Customers c
    ON c.CustomerId = l.CustomerId
WHERE l.LoanStatus = 'Active'
GROUP BY
    c.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName
HAVING COUNT(*) > 1
ORDER BY ActiveLoanCount DESC, TotalOutstandingPrincipal DESC;

/* KPI 3: Transactions flagged as fraudulent */
SELECT
    fd.FraudCaseId,
    fr.RuleCode,
    fr.RuleName,
    fd.FraudStatus,
    fd.RiskScore,
    fd.DetectionTime,
    CASE
        WHEN fd.TransactionId IS NOT NULL THEN 'AccountTransaction'
        ELSE 'CreditCardTransaction'
    END AS SourceType,
    fd.TransactionId,
    t.AccountId,
    t.Amount AS AccountTransactionAmount,
    t.TransactionDate AS AccountTransactionDate,
    fd.CardTransactionId,
    cct.CardId,
    cct.Amount AS CardTransactionAmount,
    cct.TransactionDate AS CardTransactionDate
FROM bank.FraudDetection fd
JOIN bank.FraudRules fr
    ON fr.RuleId = fd.RuleId
LEFT JOIN bank.[Transactions] t
    ON t.TransactionId = fd.TransactionId
LEFT JOIN bank.CreditCardTransactions cct
    ON cct.CardTransactionId = fd.CardTransactionId
ORDER BY fd.DetectionTime DESC;

/* KPI 4: Total loan amount issued per branch */
SELECT
    b.BranchId,
    b.BranchCode,
    b.BranchName,
    COUNT(*) AS LoanCount,
    CAST(SUM(l.PrincipalAmount) AS DECIMAL(19,2)) AS TotalLoanIssued
FROM bank.Loans l
JOIN bank.Branches b
    ON b.BranchId = l.BranchId
GROUP BY
    b.BranchId,
    b.BranchCode,
    b.BranchName
ORDER BY TotalLoanIssued DESC;

/* KPI 5: Multiple large transactions (> $10,000) within < 1 hour */
WITH LargeTx AS
(
    SELECT
        t.TransactionId,
        t.AccountId,
        t.TransactionDate,
        t.Amount
    FROM bank.[Transactions] t
    WHERE t.Amount > 10000
      AND t.TransactionStatus = 'Posted'
),
Pairs AS
(
    SELECT
        lt1.AccountId,
        lt1.TransactionId AS TransactionId1,
        lt1.TransactionDate AS TransactionDate1,
        lt1.Amount AS Amount1,
        lt2.TransactionId AS TransactionId2,
        lt2.TransactionDate AS TransactionDate2,
        lt2.Amount AS Amount2,
        DATEDIFF(MINUTE, lt1.TransactionDate, lt2.TransactionDate) AS MinutesDiff
    FROM LargeTx lt1
    JOIN LargeTx lt2
        ON lt1.AccountId = lt2.AccountId
       AND lt1.TransactionId < lt2.TransactionId
       AND lt2.TransactionDate > lt1.TransactionDate
       AND lt2.TransactionDate < DATEADD(HOUR, 1, lt1.TransactionDate)
)
SELECT
    p.AccountId,
    p.TransactionId1,
    p.Amount1,
    p.TransactionDate1,
    p.TransactionId2,
    p.Amount2,
    p.TransactionDate2,
    p.MinutesDiff
FROM Pairs p
ORDER BY p.TransactionDate1 DESC, p.AccountId;

/* KPI 6: Transactions from different countries within 10 minutes */
WITH TxPerCustomer AS
(
    SELECT
        ah.CustomerId,
        t.TransactionId,
        t.AccountId,
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
),
GeoVelocity AS
(
    SELECT
        tx.CustomerId,
        tx.PrevTransactionId,
        tx.TransactionId,
        tx.PrevTransactionDate,
        tx.TransactionDate,
        tx.PrevCountryId,
        tx.CountryId,
        DATEDIFF(MINUTE, tx.PrevTransactionDate, tx.TransactionDate) AS MinutesDiff
    FROM TxPerCustomer tx
    WHERE tx.PrevCountryId IS NOT NULL
      AND tx.PrevCountryId <> tx.CountryId
      AND DATEDIFF(MINUTE, tx.PrevTransactionDate, tx.TransactionDate) <= 10
)
SELECT
    gv.CustomerId,
    c.CustomerNumber,
    c.FirstName,
    c.LastName,
    gv.PrevTransactionId,
    prevCountry.CountryName AS PrevCountry,
    gv.PrevTransactionDate,
    gv.TransactionId,
    currCountry.CountryName AS CurrentCountry,
    gv.TransactionDate,
    gv.MinutesDiff
FROM GeoVelocity gv
JOIN bank.Customers c
    ON c.CustomerId = gv.CustomerId
JOIN bank.Countries prevCountry
    ON prevCountry.CountryId = gv.PrevCountryId
JOIN bank.Countries currCountry
    ON currCountry.CountryId = gv.CountryId
ORDER BY gv.TransactionDate DESC;
GO
