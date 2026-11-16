USE HealthcareDW;
GO

CREATE OR ALTER VIEW etl.vPatient_LoadReady
AS
SELECT
    p.Source_Code,
    p.Source_Patient_ID,
    p.Patient_Name,
    p.Gender,
    p.Date_of_Birth,

    NULLIF(LTRIM(RTRIM(e.City)), N'') AS City,
    NULLIF(LTRIM(RTRIM(e.Blood_Group)), N'') AS Blood_Group,
    NULLIF(LTRIM(RTRIM(c.insurance_provider)), N'')
        AS Insurance_Provider

FROM etl.vPatient_Prepared AS p

LEFT JOIN stg.Excel_Patients AS e
    ON p.Source_Code = N'EXCEL'
   AND p.Source_Patient_ID =
       LTRIM(RTRIM(CONVERT(nvarchar(500), e.Patient_ID)))

LEFT JOIN stg.CSV_Patients AS c
    ON p.Source_Code = N'CSV'
   AND p.Source_Patient_ID =
       LTRIM(RTRIM(CONVERT(nvarchar(500), c.patient_id)));
GO