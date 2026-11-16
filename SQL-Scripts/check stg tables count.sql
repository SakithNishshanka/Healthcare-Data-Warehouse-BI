USE HealthcareDW;
GO

-- Each source record should have its identifying ID.
-- Excel Billing uses Admission_ID, subject to this check.

SELECT 'Excel_Patients' AS Table_Name,
       COUNT(*) AS Total_Rows,
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(Patient_ID)), ''))
           AS Distinct_Nonblank_IDs,
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Patient_ID)), '') IS NULL
                THEN 1 ELSE 0 END) AS Missing_IDs
FROM stg.Excel_Patients

UNION ALL
SELECT 'Excel_Doctors', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(Doctor_ID)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Doctor_ID)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.Excel_Doctors

UNION ALL
SELECT 'Excel_Departments', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(Department_ID)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Department_ID)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.Excel_Departments

UNION ALL
SELECT 'Excel_Admissions', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(Admission_ID)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Admission_ID)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.Excel_Admissions

UNION ALL
SELECT 'Excel_Treatment', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(Treatment_ID)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Treatment_ID)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.Excel_Treatment

UNION ALL
SELECT 'Excel_Billing', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(Admission_ID)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(Admission_ID)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.Excel_Billing

UNION ALL
SELECT 'CSV_Patients', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(patient_id)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(patient_id)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.CSV_Patients

UNION ALL
SELECT 'CSV_Doctors', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(doctor_id)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(doctor_id)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.CSV_Doctors

UNION ALL
SELECT 'CSV_Appointments', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(appointment_id)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(appointment_id)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.CSV_Appointments

UNION ALL
SELECT 'CSV_Treatments', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(treatment_id)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(treatment_id)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.CSV_Treatments

UNION ALL
SELECT 'CSV_Billing', COUNT(*),
       COUNT(DISTINCT NULLIF(LTRIM(RTRIM(bill_id)), '')),
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(bill_id)), '') IS NULL
                THEN 1 ELSE 0 END)
FROM stg.CSV_Billing;