-- Step 1: Create the database if it doesn't exist
IF NOT EXISTS (
    SELECT * FROM sys.databases WHERE name = 'payments1'
)
BEGIN
    CREATE DATABASE payments1;
END
GO

-- Step 2: Use the database
USE payments1;
GO

-- Step 3: Create a Master Key if it doesn't exist
IF NOT EXISTS (
    SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Lawaniya3$12';
END
GO

-- Step 4: Create a database-scoped credential if it doesn't exist
IF NOT EXISTS (
    SELECT * FROM sys.database_scoped_credentials WHERE name = 'WorkspaceIdentity'
)
BEGIN
    CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
    WITH IDENTITY = 'Managed Identity';
END
GO

-- Step 5: Create an external data source if it doesn't exist
IF NOT EXISTS (
    SELECT * FROM sys.external_data_sources WHERE name = 'MyWorkspaceIdentityDataSource'
)
BEGIN
    CREATE EXTERNAL DATA SOURCE MyWorkspaceIdentityDataSource
    WITH (
        LOCATION = 'https://<ADLS_ACCOUNT_NAME>.dfs.core.windows.net/',
        CREDENTIAL = WorkspaceIdentity
    );
END
GO

-- Step 6: Create a view using dynamic SQL if it doesn't exist
IF NOT EXISTS (
    SELECT * FROM sys.views WHERE name = 'Accounts'
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
    CREATE VIEW Accounts AS
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
        BULK ''accounts/day1/accounts1.json'',
        DATA_SOURCE = ''MyWorkspaceIdentityDataSource'',
        FORMAT = ''CSV'',
        FIELDTERMINATOR = ''0x0b'',
        FIELDQUOTE = ''0x0b'',
        ROWTERMINATOR = ''0x0a'',
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
    ';
    EXEC sp_executesql @sql;
END
GO

-- Step 7: Query the view
SELECT * FROM Accounts;
GO
