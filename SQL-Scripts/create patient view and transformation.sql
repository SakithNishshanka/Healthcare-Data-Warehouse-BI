USE HealthcareDW;
GO

-- Create a schema for transformation views.
IF SCHEMA_ID(N'etl') IS NULL
    EXEC(N'CREATE SCHEMA etl AUTHORIZATION dbo;');
GO

CREATE OR ALTER VIEW etl.vPatient_Prepared
AS
WITH CombinedPatients AS (
    SELECT
        N'EXCEL' AS Source_Code,

        LTRIM(RTRIM(CONVERT(nvarchar(500), Patient_ID)))
            AS Source_Patient_ID,

        NULLIF(LTRIM(RTRIM(Patient_Name)), N'')
            AS Patient_Name,

        NULLIF(LTRIM(RTRIM(Gender)), N'')
            AS Original_Gender,

        CONVERT(date,
            CONVERT(datetime2, Date_of_Birth, 120))
            AS Date_of_Birth

    FROM stg.Excel_Patients

    UNION ALL

    SELECT
        N'CSV' AS Source_Code,

        LTRIM(RTRIM(CONVERT(nvarchar(500), patient_id)))
            AS Source_Patient_ID,

        NULLIF(
            LTRIM(RTRIM(
                CONCAT(
                    LTRIM(RTRIM(first_name)),
                    N' ',
                    LTRIM(RTRIM(last_name))
                )
            )),
            N''
        ) AS Patient_Name,

        NULLIF(LTRIM(RTRIM(gender)), N'')
            AS Original_Gender,

        CONVERT(date,
            CONVERT(datetime2, date_of_birth, 120))
            AS Date_of_Birth

    FROM stg.CSV_Patients
)
SELECT
    Source_Code,
    Source_Patient_ID,
    Patient_Name,
    Original_Gender,

    CASE
        WHEN UPPER(Original_Gender) IN (N'M', N'MALE')
            THEN N'Male'
        WHEN UPPER(Original_Gender) IN (N'F', N'FEMALE')
            THEN N'Female'
        ELSE Original_Gender
    END AS Gender,

    Date_of_Birth

FROM CombinedPatients;
GO


-- Check counts by source.
SELECT
    Source_Code,
    COUNT(*) AS Patient_Count
FROM etl.vPatient_Prepared
GROUP BY Source_Code;

-- Preview the prepared CSV names and dates.
SELECT TOP (10)
    Source_Code,
    Source_Patient_ID,
    Patient_Name,
    Original_Gender,
    Gender,
    Date_of_Birth
FROM etl.vPatient_Prepared
WHERE Source_Code = N'CSV'
ORDER BY Source_Patient_ID;

-- Review all gender categories after transformation.
SELECT
    Source_Code,
    Gender,
    COUNT(*) AS Patient_Count
FROM etl.vPatient_Prepared
GROUP BY Source_Code, Gender
ORDER BY Source_Code, Gender;

-- Check for missing full names.
SELECT COUNT(*) AS Missing_Patient_Names
FROM etl.vPatient_Prepared
WHERE Patient_Name IS NULL;