-- Step 1: Create the database
CREATE DATABASE sqlcmdpayer11;
GO

-- Step 2: Use the database
USE sqlcmdpayer11;
GO

-- Step 3: Create a Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Lawaniya3$12';
GO

-- Step 4: Create a database-scoped credential
CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
WITH IDENTITY = 'Managed Identity';
GO

-- Step 5: Create an external data source
CREATE EXTERNAL DATA SOURCE MyWorkspaceIdentityDataSource
WITH (
    LOCATION = 'https://adlssynapsepayeralawaniy.dfs.core.windows.net/',
    CREDENTIAL = WorkspaceIdentity
);
GO

-- Step 6: Create a view
CREATE VIEW UpdatedAccountYatharth11 AS
SELECT
    event.[type],
    event.[version],
    event.[entityName],
    event.[Source],
    event.[tenantId],
    event.[id],
    event.[eventId],
    event.[CreatedOn],
    event.[eventVersion],
    payload.[organizationId],
    payload.[name],
    payload.[routingNumber],
    payload.[accountNumberLasFourDigits],
    payload.[accountType]
FROM OPENROWSET(
    BULK 'accounts/day1/accounts1.json',
    DATA_SOURCE = 'MyWorkspaceIdentityDataSource',
    FORMAT = 'CSV',
    FIELDTERMINATOR = '0x0b',
    FIELDQUOTE = '0x0b',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 1
)
WITH (
    BulkColumn NVARCHAR(MAX)
) AS result
CROSS APPLY OPENJSON(result.BulkColumn)
WITH (
    [type] NVARCHAR(50),
    [version] INT,
    [entityName] NVARCHAR(50),
    [Source] NVARCHAR(50),
    [tenantId] NVARCHAR(50),
    [id] NVARCHAR(50),
    [eventId] NVARCHAR(50),
    [CreatedOn] NVARCHAR(50),
    [eventVersion] NVARCHAR(50),
    [payload] NVARCHAR(MAX) AS JSON
) AS event
CROSS APPLY OPENJSON(event.payload)
WITH (
    [organizationId] NVARCHAR(50),
    [name] NVARCHAR(50),
    [routingNumber] NVARCHAR(50),
    [accountNumberLasFourDigits] NVARCHAR(50),
    [accountType] NVARCHAR(50)
) AS payload;
GO

-- Step 7: Query the view
SELECT * FROM UpdatedAccountYatharth11;
GO
