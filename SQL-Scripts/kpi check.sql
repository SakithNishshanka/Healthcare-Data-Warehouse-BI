USE HealthcareDW;
GO

SELECT
    COUNT(*) AS Total_Admissions,
    COUNT(DISTINCT Patient_Key) AS Unique_Patients,
    COUNT(DISTINCT Doctor_Key) AS Doctors_With_Admissions,
    AVG(CONVERT(decimal(18,2), Length_Of_Stay_Days))
        AS Average_Stay_Days
FROM mart.FactAdmissions;