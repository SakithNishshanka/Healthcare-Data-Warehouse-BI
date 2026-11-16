USE HealthcareDW;
GO

SELECT
    LTRIM(RTRIM(Specialization)) AS Specialization,
    COUNT(*) AS Doctor_Count
FROM stg.Excel_Doctors
GROUP BY LTRIM(RTRIM(Specialization))
ORDER BY Specialization;


USE HealthcareDW;
GO

CREATE OR ALTER VIEW etl.vDoctor_Validated
AS
SELECT
    Source_Code,
    Source_Doctor_ID,
    Doctor_Name,

    -- Preserve the source value for traceability.
    Specialization AS Original_Specialization,

    -- Do not use unverified Excel values analytically.
    CASE
        WHEN Source_Code = N'EXCEL'
            THEN CAST(NULL AS nvarchar(500))
        ELSE Specialization
    END AS Specialization,

    CASE
        WHEN Source_Code = N'EXCEL'
            THEN N'Needs verification'
        ELSE N'Source value retained'
    END AS Specialization_Quality,

    Source_Department_ID,
    Consultation_Fee,
    Years_Experience,
    Hospital_Branch

FROM etl.vDoctor_Prepared;
GO


SELECT
    Source_Code,
    Specialization_Quality,
    COUNT(*) AS Doctor_Count,
    COUNT(Specialization) AS Available_Specializations
FROM etl.vDoctor_Validated
GROUP BY
    Source_Code,
    Specialization_Quality;