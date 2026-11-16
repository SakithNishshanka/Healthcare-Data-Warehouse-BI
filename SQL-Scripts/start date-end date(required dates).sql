USE HealthcareDW;
GO

WITH AllDates AS (
    SELECT CONVERT(date, CONVERT(datetime2, [Date], 120))
        AS Full_Date
    FROM stg.Excel_Calendar

    UNION ALL
    SELECT CONVERT(date, CONVERT(datetime2, Admission_Date, 120))
    FROM stg.Excel_Admissions

    UNION ALL
    SELECT CONVERT(date, CONVERT(datetime2, Discharge_Date, 120))
    FROM stg.Excel_Admissions

    UNION ALL
    SELECT CONVERT(date, CONVERT(datetime2, appointment_date, 120))
    FROM stg.CSV_Appointments

    UNION ALL
    SELECT CONVERT(date, CONVERT(datetime2, treatment_date, 120))
    FROM stg.CSV_Treatments

    UNION ALL
    SELECT CONVERT(date, CONVERT(datetime2, bill_date, 120))
    FROM stg.CSV_Billing
)
SELECT
    MIN(Full_Date) AS Start_Date,
    MAX(Full_Date) AS End_Date,
    DATEDIFF(DAY, MIN(Full_Date), MAX(Full_Date)) + 1
        AS Required_Calendar_Days
FROM AllDates;


