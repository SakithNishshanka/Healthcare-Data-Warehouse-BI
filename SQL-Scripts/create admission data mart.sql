USE HealthcareDW;
GO

IF SCHEMA_ID(N'mart') IS NULL
    EXEC(N'CREATE SCHEMA mart AUTHORIZATION dbo;');
GO


-- Main fact: one row per Excel hospital admission.
CREATE OR ALTER VIEW mart.FactAdmissions
AS
SELECT
    f.Admission_Key,
    f.Source_Key,
    f.Source_Admission_ID,
    f.Patient_Key,
    f.Doctor_Key,
    f.Admission_Date_Key,
    f.Discharge_Date_Key,
    f.Room_Key,
    f.Admission_Count,
    f.Length_Of_Stay_Days
FROM dbo.FactAdmissions AS f
JOIN dbo.DimSource AS s
    ON s.Source_Key = f.Source_Key
WHERE s.Source_Code = 'EXCEL';
GO


-- Only patients referenced by this mart.
CREATE OR ALTER VIEW mart.DimPatient
AS
SELECT
    p.Patient_Key,
    p.Source_Code,
    p.Source_Patient_ID,
    p.Patient_Name,
    p.Gender,
    p.Date_Of_Birth,
    p.City,
    p.Blood_Group
FROM dbo.DimPatient AS p
WHERE EXISTS (
    SELECT 1
    FROM mart.FactAdmissions AS f
    WHERE f.Patient_Key = p.Patient_Key
);
GO


USE HealthcareDW;
GO

-- Only doctors referenced by the Admissions Data Mart.
CREATE OR ALTER VIEW mart.DimDoctor
AS
SELECT
    d.Doctor_Key,
    d.Source_Code,
    d.Source_Doctor_ID,
    d.Doctor_Name,
    d.Department_Key,

    -- Keep this column for existing Power BI visuals.
    dep.Department_Name
FROM dbo.DimDoctor AS d
LEFT JOIN dbo.DimDepartment AS dep
    ON dep.Department_Key = d.Department_Key
WHERE EXISTS
(
    SELECT 1
    FROM mart.FactAdmissions AS f
    WHERE f.Doctor_Key = d.Doctor_Key
);
GO


-- Only departments referenced by this mart's doctors.
CREATE OR ALTER VIEW mart.DimDepartment
AS
SELECT
    dep.Department_Key,
    dep.Source_Code,
    dep.Source_Department_ID,
    dep.Department_Name,
    dep.Floor_Number
FROM dbo.DimDepartment AS dep
WHERE EXISTS
(
    SELECT 1
    FROM mart.DimDoctor AS d
    WHERE d.Department_Key = dep.Department_Key
);
GO


-- Validate the doctor-to-department mapping.
SELECT
    COUNT(*) AS Total_Doctors,
    COUNT(dep.Department_Key) AS Doctors_With_Department,
    SUM(
        CASE WHEN dep.Department_Key IS NULL THEN 1 ELSE 0 END
    ) AS Doctors_Without_Department
FROM mart.DimDoctor AS d
LEFT JOIN mart.DimDepartment AS dep
    ON dep.Department_Key = d.Department_Key;

SELECT *
FROM mart.DimDepartment
ORDER BY Department_Key;
GO


-- Keep a continuous calendar, including days with no admissions.
CREATE OR ALTER VIEW mart.DimDate
AS
SELECT
    Date_Key,
    Full_Date,
    Calendar_Year,
    Quarter_No,
    Month_No,
    Month_Name,
    Day_Of_Month
FROM dbo.DimDate;
GO


CREATE OR ALTER VIEW mart.DimRoom
AS
SELECT
    r.Room_Key,
    r.Room_Type
FROM dbo.DimRoom AS r
WHERE EXISTS (
    SELECT 1
    FROM mart.FactAdmissions AS f
    WHERE f.Room_Key = r.Room_Key
);
GO


CREATE OR ALTER VIEW mart.DimSource
AS
SELECT
    s.Source_Key,
    s.Source_Code,
    s.Source_Name
FROM dbo.DimSource AS s
WHERE EXISTS (
    SELECT 1
    FROM mart.FactAdmissions AS f
    WHERE f.Source_Key = s.Source_Key
);
GO


SELECT N'FactAdmissions' AS Mart_View, COUNT(*) AS Row_Count
FROM mart.FactAdmissions

UNION ALL
SELECT N'DimPatient', COUNT(*) FROM mart.DimPatient

UNION ALL
SELECT N'DimDoctor', COUNT(*) FROM mart.DimDoctor

UNION ALL
SELECT N'DimDate', COUNT(*) FROM mart.DimDate

UNION ALL
SELECT N'DimRoom', COUNT(*) FROM mart.DimRoom

UNION ALL
SELECT N'DimSource', COUNT(*) FROM mart.DimSource

UNION ALL
SELECT N'DimDepartment', COUNT(*) FROM mart.DimDepartment;