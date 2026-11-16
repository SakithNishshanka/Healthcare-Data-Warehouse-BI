USE HealthcareDW;
GO

-- 1. Room categories
CREATE OR ALTER VIEW etl.vRoom_Prepared
AS
SELECT DISTINCT
    NULLIF(LTRIM(RTRIM(Room_Type)), N'') AS Room_Type
FROM stg.Excel_Admissions;
GO


-- 2. Treatment categories by source
CREATE OR ALTER VIEW etl.vTreatmentType_Prepared
AS
SELECT DISTINCT
    N'EXCEL' AS Source_Code,
    NULLIF(LTRIM(RTRIM(Treatment_Type)), N'') AS Treatment_Type
FROM stg.Excel_Treatment

UNION ALL

SELECT DISTINCT
    N'CSV' AS Source_Code,
    NULLIF(LTRIM(RTRIM(treatment_type)), N'') AS Treatment_Type
FROM stg.CSV_Treatments;
GO


-- 3. Actual payment method/status combinations
CREATE OR ALTER VIEW etl.vPayment_Prepared
AS
SELECT DISTINCT
    N'EXCEL' AS Source_Code,
    NULLIF(LTRIM(RTRIM(Payment_Mode)), N'') AS Payment_Method,
    NULLIF(LTRIM(RTRIM(Payment_Status)), N'') AS Payment_Status
FROM stg.Excel_Billing

UNION ALL

SELECT DISTINCT
    N'CSV' AS Source_Code,
    NULLIF(LTRIM(RTRIM(payment_method)), N'') AS Payment_Method,
    NULLIF(LTRIM(RTRIM(payment_status)), N'') AS Payment_Status
FROM stg.CSV_Billing;
GO


-- 4. Prepared admissions
CREATE OR ALTER VIEW etl.vAdmissions_Prepared
AS
WITH Prepared AS (
    SELECT
        N'EXCEL' AS Source_Code,

        LTRIM(RTRIM(CONVERT(nvarchar(500), Admission_ID)))
            AS Source_Admission_ID,

        LTRIM(RTRIM(CONVERT(nvarchar(500), Patient_ID)))
            AS Source_Patient_ID,

        LTRIM(RTRIM(CONVERT(nvarchar(500), Doctor_ID)))
            AS Source_Doctor_ID,

        CONVERT(date, CONVERT(datetime2, Admission_Date, 120))
            AS Admission_Date,

        CONVERT(date, CONVERT(datetime2, Discharge_Date, 120))
            AS Discharge_Date,

        NULLIF(LTRIM(RTRIM(Room_Type)), N'')
            AS Room_Type

    FROM stg.Excel_Admissions
)
SELECT
    Source_Code,
    Source_Admission_ID,
    Source_Patient_ID,
    Source_Doctor_ID,
    Admission_Date,
    Discharge_Date,
    Room_Type,

    YEAR(Admission_Date) * 10000
        + MONTH(Admission_Date) * 100
        + DAY(Admission_Date) AS Admission_Date_Key,

    YEAR(Discharge_Date) * 10000
        + MONTH(Discharge_Date) * 100
        + DAY(Discharge_Date) AS Discharge_Date_Key,

    DATEDIFF(DAY, Admission_Date, Discharge_Date)
        AS Length_Of_Stay_Days,

    1 AS Admission_Count

FROM Prepared;
GO


-- 5. Prepared appointments
CREATE OR ALTER VIEW etl.vAppointments_Prepared
AS
WITH Prepared AS (
    SELECT
        N'CSV' AS Source_Code,

        LTRIM(RTRIM(CONVERT(nvarchar(500), appointment_id)))
            AS Source_Appointment_ID,

        LTRIM(RTRIM(CONVERT(nvarchar(500), patient_id)))
            AS Source_Patient_ID,

        LTRIM(RTRIM(CONVERT(nvarchar(500), doctor_id)))
            AS Source_Doctor_ID,

        CONVERT(date, CONVERT(datetime2, appointment_date, 120))
            AS Appointment_Date,

        CONVERT(time(0), appointment_time)
            AS Appointment_Time,

        NULLIF(LTRIM(RTRIM(reason_for_visit)), N'')
            AS Reason_For_Visit,

        NULLIF(LTRIM(RTRIM(status)), N'')
            AS Appointment_Status

    FROM stg.CSV_Appointments
)
SELECT
    Source_Code,
    Source_Appointment_ID,
    Source_Patient_ID,
    Source_Doctor_ID,
    Appointment_Date,
    Appointment_Time,
    Reason_For_Visit,
    Appointment_Status,

    YEAR(Appointment_Date) * 10000
        + MONTH(Appointment_Date) * 100
        + DAY(Appointment_Date) AS Appointment_Date_Key,

    1 AS Appointment_Count

FROM Prepared;
GO

-- A. Row counts
SELECT N'Room' AS Prepared_View, COUNT(*) AS Row_Count
FROM etl.vRoom_Prepared

UNION ALL
SELECT N'TreatmentType', COUNT(*)
FROM etl.vTreatmentType_Prepared

UNION ALL
SELECT N'Payment', COUNT(*)
FROM etl.vPayment_Prepared

UNION ALL
SELECT N'Admissions', COUNT(*)
FROM etl.vAdmissions_Prepared

UNION ALL
SELECT N'Appointments', COUNT(*)
FROM etl.vAppointments_Prepared;


-- B. Actual payment combinations
SELECT *
FROM etl.vPayment_Prepared
ORDER BY Source_Code, Payment_Method, Payment_Status;


-- C. Admission calculation preview
SELECT TOP (5)
    Source_Admission_ID,
    Admission_Date,
    Discharge_Date,
    Length_Of_Stay_Days,
    Admission_Date_Key,
    Discharge_Date_Key
FROM etl.vAdmissions_Prepared
ORDER BY Source_Admission_ID;


-- D. Appointment status categories
SELECT
    Appointment_Status,
    COUNT(*) AS Appointment_Count
FROM etl.vAppointments_Prepared
GROUP BY Appointment_Status;


-- E. Ensure all event dates exist in the prepared calendar
SELECT
    N'Admission date' AS Date_Check,
    COUNT(*) AS Unmatched_Dates
FROM etl.vAdmissions_Prepared AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM etl.vDate_Prepared AS d
    WHERE d.Full_Date = a.Admission_Date
)

UNION ALL

SELECT N'Discharge date', COUNT(*)
FROM etl.vAdmissions_Prepared AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM etl.vDate_Prepared AS d
    WHERE d.Full_Date = a.Discharge_Date
)

UNION ALL

SELECT N'Appointment date', COUNT(*)
FROM etl.vAppointments_Prepared AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM etl.vDate_Prepared AS d
    WHERE d.Full_Date = a.Appointment_Date
);