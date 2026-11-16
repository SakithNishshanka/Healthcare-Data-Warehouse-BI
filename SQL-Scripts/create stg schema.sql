USE HealthcareDW;
GO

IF SCHEMA_ID(N'stg') IS NULL
    EXEC(N'CREATE SCHEMA stg AUTHORIZATION dbo;');
GO

SELECT name AS Schema_Name
FROM sys.schemas
WHERE name = N'stg';

