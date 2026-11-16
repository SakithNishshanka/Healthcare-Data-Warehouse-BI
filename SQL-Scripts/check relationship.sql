USE HealthcareDW;
GO

SELECT 'Excel: Admissions → Patients' AS Relationship_Check,
       COUNT(*) AS Unmatched_Rows
FROM stg.Excel_Admissions AS a
WHERE NOT EXISTS (
    SELECT 1 FROM stg.Excel_Patients AS p
    WHERE LTRIM(RTRIM(p.Patient_ID)) =
          LTRIM(RTRIM(a.Patient_ID))
)

UNION ALL
SELECT 'Excel: Admissions → Doctors', COUNT(*)
FROM stg.Excel_Admissions AS a
WHERE NOT EXISTS (
    SELECT 1 FROM stg.Excel_Doctors AS d
    WHERE LTRIM(RTRIM(d.Doctor_ID)) =
          LTRIM(RTRIM(a.Doctor_ID))
)

UNION ALL
SELECT 'Excel: Doctors → Departments', COUNT(*)
FROM stg.Excel_Doctors AS d
WHERE NOT EXISTS (
    SELECT 1 FROM stg.Excel_Departments AS dep
    WHERE LTRIM(RTRIM(dep.Department_ID)) =
          LTRIM(RTRIM(d.Department_ID))
)

UNION ALL
SELECT 'Excel: Treatment → Admissions', COUNT(*)
FROM stg.Excel_Treatment AS t
WHERE NOT EXISTS (
    SELECT 1 FROM stg.Excel_Admissions AS a
    WHERE LTRIM(RTRIM(a.Admission_ID)) =
          LTRIM(RTRIM(t.Admission_ID))
)

UNION ALL
SELECT 'Excel: Billing → Admissions', COUNT(*)
FROM stg.Excel_Billing AS b
WHERE NOT EXISTS (
    SELECT 1 FROM stg.Excel_Admissions AS a
    WHERE LTRIM(RTRIM(a.Admission_ID)) =
          LTRIM(RTRIM(b.Admission_ID))
)

UNION ALL
SELECT 'CSV: Appointments → Patients', COUNT(*)
FROM stg.CSV_Appointments AS a
WHERE NOT EXISTS (
    SELECT 1 FROM stg.CSV_Patients AS p
    WHERE LTRIM(RTRIM(p.patient_id)) =
          LTRIM(RTRIM(a.patient_id))
)

UNION ALL
SELECT 'CSV: Appointments → Doctors', COUNT(*)
FROM stg.CSV_Appointments AS a
WHERE NOT EXISTS (
    SELECT 1 FROM stg.CSV_Doctors AS d
    WHERE LTRIM(RTRIM(d.doctor_id)) =
          LTRIM(RTRIM(a.doctor_id))
)

UNION ALL
SELECT 'CSV: Treatments → Appointments', COUNT(*)
FROM stg.CSV_Treatments AS t
WHERE NOT EXISTS (
    SELECT 1 FROM stg.CSV_Appointments AS a
    WHERE LTRIM(RTRIM(a.appointment_id)) =
          LTRIM(RTRIM(t.appointment_id))
)

UNION ALL
SELECT 'CSV: Billing → Patients', COUNT(*)
FROM stg.CSV_Billing AS b
WHERE NOT EXISTS (
    SELECT 1 FROM stg.CSV_Patients AS p
    WHERE LTRIM(RTRIM(p.patient_id)) =
          LTRIM(RTRIM(b.patient_id))
)

UNION ALL
SELECT 'CSV: Billing → Treatments', COUNT(*)
FROM stg.CSV_Billing AS b
WHERE NOT EXISTS (
    SELECT 1 FROM stg.CSV_Treatments AS t
    WHERE LTRIM(RTRIM(t.treatment_id)) =
          LTRIM(RTRIM(b.treatment_id))
);