USE HealthcareDW;
GO

CREATE OR ALTER VIEW etl.vDoctor_Prepared
AS

SELECT
    N'EXCEL' AS Source_Code,

    LTRIM(RTRIM(CONVERT(nvarchar(500), d.Doctor_ID)))
        AS Source_Doctor_ID,

    NULLIF(LTRIM(RTRIM(d.Doctor_Name)), N'')
        AS Doctor_Name,

    NULLIF(LTRIM(RTRIM(d.Specialization)), N'')
        AS Specialization,

    LTRIM(RTRIM(CONVERT(nvarchar(500), d.Department_ID)))
        AS Source_Department_ID,

    

    CONVERT(
        decimal(28,6),
        NULLIF(LTRIM(RTRIM(
            CONVERT(nvarchar(500), d.Consultation_Fee)
        )), N'')
    ) AS Consultation_Fee,

    CAST(NULL AS decimal(28,6)) AS Years_Experience,

    CAST(NULL AS nvarchar(500)) AS Hospital_Branch

FROM stg.Excel_Doctors AS d

LEFT JOIN stg.Excel_Departments AS dep
    ON LTRIM(RTRIM(CONVERT(nvarchar(500), d.Department_ID)))
     = LTRIM(RTRIM(CONVERT(nvarchar(500), dep.Department_ID)))

UNION ALL

SELECT
    N'CSV' AS Source_Code,

    LTRIM(RTRIM(CONVERT(nvarchar(500), doctor_id)))
        AS Source_Doctor_ID,

    NULLIF(
        LTRIM(RTRIM(
            CONCAT(
                LTRIM(RTRIM(first_name)),
                N' ',
                LTRIM(RTRIM(last_name))
            )
        )),
        N''
    ) AS Doctor_Name,

    NULLIF(LTRIM(RTRIM(specialization)), N'')
        AS Specialization,

    CAST(NULL AS nvarchar(500)) AS Source_Department_ID,

    

    CAST(NULL AS decimal(28,6)) AS Consultation_Fee,

    CONVERT(
        decimal(28,6),
        NULLIF(LTRIM(RTRIM(
            CONVERT(nvarchar(500), years_experience)
        )), N'')
    ) AS Years_Experience,

    NULLIF(LTRIM(RTRIM(hospital_branch)), N'')
        AS Hospital_Branch

FROM stg.CSV_Doctors;
GO

-- Expected: CSV = 10, EXCEL = 200.
SELECT
    Source_Code,
    COUNT(*) AS Doctor_Count
FROM etl.vDoctor_Prepared
GROUP BY Source_Code;

-- Preview CSV full names and attributes.
SELECT TOP (10) *
FROM etl.vDoctor_Prepared
WHERE Source_Code = N'CSV'
ORDER BY Source_Doctor_ID;

-- Preview Excel department names.
SELECT TOP (10)
    Source_Doctor_ID,
    Doctor_Name,
    Specialization,
    Source_Department_ID,
    Consultation_Fee
FROM etl.vDoctor_Prepared
WHERE Source_Code = N'EXCEL'
ORDER BY Source_Doctor_ID;

-- Check required descriptive fields.
SELECT
    Source_Code,
    SUM(CASE WHEN Doctor_Name IS NULL
             THEN 1 ELSE 0 END) AS Missing_Doctor_Names,
    SUM(CASE WHEN Specialization IS NULL
             THEN 1 ELSE 0 END) AS Missing_Specializations,
    SUM(CASE WHEN Source_Code = N'EXCEL'
                  AND Department_Name IS NULL
             THEN 1 ELSE 0 END) AS Missing_Excel_Departments
FROM etl.vDoctor_Prepared
GROUP BY Source_Code;