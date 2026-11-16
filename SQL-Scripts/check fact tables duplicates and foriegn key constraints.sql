USE HealthcareDW;
GO

SELECT
    N'Admissions' AS Fact_Table,
    Source_Key,
    Source_Admission_ID AS Source_Record_ID,
    COUNT(*) AS Occurrences
FROM dbo.FactAdmissions
GROUP BY Source_Key, Source_Admission_ID
HAVING COUNT(*) > 1

UNION ALL

SELECT
    N'Appointments',
    Source_Key,
    Source_Appointment_ID,
    COUNT(*)
FROM dbo.FactAppointments
GROUP BY Source_Key, Source_Appointment_ID
HAVING COUNT(*) > 1

UNION ALL

SELECT
    N'Treatments',
    Source_Key,
    Source_Treatment_ID,
    COUNT(*)
FROM dbo.FactTreatments
GROUP BY Source_Key, Source_Treatment_ID
HAVING COUNT(*) > 1

UNION ALL

SELECT
    N'Billing',
    Source_Key,
    Source_Bill_ID,
    COUNT(*)
FROM dbo.FactBilling
GROUP BY Source_Key, Source_Bill_ID
HAVING COUNT(*) > 1;


-- Foreign-key configuration
SELECT
    OBJECT_NAME(parent_object_id) AS Table_Name,
    name AS Foreign_Key_Name,
    is_disabled,
    is_not_trusted
FROM sys.foreign_keys
WHERE OBJECT_SCHEMA_NAME(parent_object_id) = N'dbo'
  AND OBJECT_NAME(parent_object_id) IN (
      N'FactAdmissions',
      N'FactAppointments',
      N'FactTreatments',
      N'FactBilling'
  )
ORDER BY Table_Name, Foreign_Key_Name;


-- Check existing records against constraints
DBCC CHECKCONSTRAINTS ('dbo.FactAdmissions')
WITH ALL_CONSTRAINTS;

DBCC CHECKCONSTRAINTS ('dbo.FactAppointments')
WITH ALL_CONSTRAINTS;

DBCC CHECKCONSTRAINTS ('dbo.FactTreatments')
WITH ALL_CONSTRAINTS;

DBCC CHECKCONSTRAINTS ('dbo.FactBilling')
WITH ALL_CONSTRAINTS;


