USE HealthcareDW;
GO

CREATE OR ALTER VIEW etl.vTreatments_Prepared
AS

SELECT
    N'EXCEL' AS Source_Code,

    LTRIM(RTRIM(CONVERT(nvarchar(500), t.Treatment_ID)))
        AS Source_Treatment_ID,

    LTRIM(RTRIM(CONVERT(nvarchar(500), t.Admission_ID)))
        AS Source_Admission_ID,

    CAST(NULL AS nvarchar(500)) AS Source_Appointment_ID,

    a.Source_Patient_ID,
    a.Source_Doctor_ID,

    NULLIF(LTRIM(RTRIM(t.Treatment_Type)), N'')
        AS Treatment_Type,

    CAST(NULL AS date) AS Treatment_Date,
    CAST(NULL AS int) AS Treatment_Date_Key,

    CONVERT(decimal(28,6), t.Treatment_Cost)
        AS Treatment_Cost,

    CONVERT(decimal(28,6), t.Medicine_Cost)
        AS Medicine_Cost,

    CONVERT(decimal(28,6), t.Lab_Cost)
        AS Lab_Cost,

    1 AS Treatment_Count

FROM stg.Excel_Treatment AS t
LEFT JOIN etl.vAdmissions_Prepared AS a
    ON LTRIM(RTRIM(CONVERT(nvarchar(500), t.Admission_ID)))
       = a.Source_Admission_ID

UNION ALL

SELECT
    N'CSV',

    LTRIM(RTRIM(CONVERT(nvarchar(500), t.treatment_id))),

    CAST(NULL AS nvarchar(500)),

    LTRIM(RTRIM(CONVERT(nvarchar(500), t.appointment_id))),

    a.Source_Patient_ID,
    a.Source_Doctor_ID,

    NULLIF(LTRIM(RTRIM(t.treatment_type)), N''),

    dt.Treatment_Date,

    YEAR(dt.Treatment_Date) * 10000
        + MONTH(dt.Treatment_Date) * 100
        + DAY(dt.Treatment_Date),

    CONVERT(decimal(28,6), t.cost),

    CAST(NULL AS decimal(28,6)),
    CAST(NULL AS decimal(28,6)),

    1

FROM stg.CSV_Treatments AS t
LEFT JOIN etl.vAppointments_Prepared AS a
    ON LTRIM(RTRIM(CONVERT(nvarchar(500), t.appointment_id)))
       = a.Source_Appointment_ID
CROSS APPLY (
    SELECT CONVERT(date,
        CONVERT(datetime2, t.treatment_date, 120))
        AS Treatment_Date
) AS dt;
GO




CREATE OR ALTER VIEW etl.vBilling_Prepared
AS

SELECT
    N'EXCEL' AS Source_Code,

    LTRIM(RTRIM(CONVERT(nvarchar(500), b.Admission_ID)))
        AS Source_Bill_ID,

    LTRIM(RTRIM(CONVERT(nvarchar(500), b.Admission_ID)))
        AS Source_Admission_ID,

    CAST(NULL AS nvarchar(500)) AS Source_Treatment_ID,

    a.Source_Patient_ID,
    a.Source_Doctor_ID,

    CAST(NULL AS date) AS Bill_Date,
    CAST(NULL AS int) AS Bill_Date_Key,

    CONVERT(decimal(28,6), b.Total_Bill)
        AS Bill_Amount,

    CONVERT(decimal(28,6), b.Insurance_Cover)
        AS Insurance_Cover,

    CONVERT(decimal(28,6), b.Final_Amount_Payable)
        AS Final_Amount_Payable,

    NULLIF(LTRIM(RTRIM(b.Payment_Mode)), N'')
        AS Payment_Method,

    NULLIF(LTRIM(RTRIM(b.Payment_Status)), N'')
        AS Payment_Status,

    CONVERT(decimal(28,6), b.EMI_Months)
        AS EMI_Months,

    CONVERT(decimal(28,6), b.Monthly_EMI)
        AS Monthly_EMI,

    1 AS Bill_Count

FROM stg.Excel_Billing AS b
LEFT JOIN etl.vAdmissions_Prepared AS a
    ON LTRIM(RTRIM(CONVERT(nvarchar(500), b.Admission_ID)))
       = a.Source_Admission_ID

UNION ALL

SELECT
    N'CSV',

    LTRIM(RTRIM(CONVERT(nvarchar(500), b.bill_id))),

    CAST(NULL AS nvarchar(500)),

    LTRIM(RTRIM(CONVERT(nvarchar(500), b.treatment_id))),

    LTRIM(RTRIM(CONVERT(nvarchar(500), b.patient_id))),

    t.Source_Doctor_ID,

    dt.Bill_Date,

    YEAR(dt.Bill_Date) * 10000
        + MONTH(dt.Bill_Date) * 100
        + DAY(dt.Bill_Date),

    CONVERT(decimal(28,6), b.amount),

    CAST(NULL AS decimal(28,6)),
    CAST(NULL AS decimal(28,6)),

    NULLIF(LTRIM(RTRIM(b.payment_method)), N''),
    NULLIF(LTRIM(RTRIM(b.payment_status)), N''),

    CAST(NULL AS decimal(28,6)),
    CAST(NULL AS decimal(28,6)),

    1

FROM stg.CSV_Billing AS b
LEFT JOIN etl.vTreatments_Prepared AS t
    ON t.Source_Code = N'CSV'
   AND LTRIM(RTRIM(CONVERT(nvarchar(500), b.treatment_id)))
       = t.Source_Treatment_ID
CROSS APPLY (
    SELECT CONVERT(date,
        CONVERT(datetime2, b.bill_date, 120))
        AS Bill_Date
) AS dt;
GO




-- Counts and missing patient/doctor links
SELECT
    N'Treatments' AS Prepared_View,
    Source_Code,
    COUNT(*) AS Row_Count,
    SUM(CASE WHEN Source_Patient_ID IS NULL
             THEN 1 ELSE 0 END) AS Missing_Patient_Links,
    SUM(CASE WHEN Source_Doctor_ID IS NULL
             THEN 1 ELSE 0 END) AS Missing_Doctor_Links
FROM etl.vTreatments_Prepared
GROUP BY Source_Code

UNION ALL

SELECT
    N'Billing',
    Source_Code,
    COUNT(*),
    SUM(CASE WHEN Source_Patient_ID IS NULL
             THEN 1 ELSE 0 END),
    SUM(CASE WHEN Source_Doctor_ID IS NULL
             THEN 1 ELSE 0 END)
FROM etl.vBilling_Prepared
GROUP BY Source_Code;


-- Inspect samples from both sources
SELECT TOP (3) *
FROM etl.vTreatments_Prepared
WHERE Source_Code = N'EXCEL';

SELECT TOP (3) *
FROM etl.vTreatments_Prepared
WHERE Source_Code = N'CSV';

SELECT TOP (3) *
FROM etl.vBilling_Prepared
WHERE Source_Code = N'EXCEL';

SELECT TOP (3) *
FROM etl.vBilling_Prepared
WHERE Source_Code = N'CSV';