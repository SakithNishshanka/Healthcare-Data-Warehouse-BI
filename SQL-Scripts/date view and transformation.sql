USE HealthcareDW;
GO

CREATE OR ALTER VIEW etl.vDate_Prepared
AS
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
),
DateRange AS (
    SELECT
        MIN(Full_Date) AS Start_Date,
        MAX(Full_Date) AS End_Date
    FROM AllDates
),
Digits AS (
    SELECT n
    FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS d(n)
),
Numbers AS (
    SELECT
        a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n AS n
    FROM Digits AS a
    CROSS JOIN Digits AS b
    CROSS JOIN Digits AS c
    CROSS JOIN Digits AS d
    CROSS JOIN Digits AS e
),
CalendarDates AS (
    SELECT DATEADD(DAY, n.n, r.Start_Date) AS Full_Date
    FROM DateRange AS r
    JOIN Numbers AS n
        ON n.n <= DATEDIFF(DAY, r.Start_Date, r.End_Date)
)
SELECT
    YEAR(Full_Date) * 10000
        + MONTH(Full_Date) * 100
        + DAY(Full_Date) AS Date_Key,

    Full_Date,

    CAST(YEAR(Full_Date) AS smallint) AS Calendar_Year,

    CAST(DATEPART(QUARTER, Full_Date) AS tinyint) AS Quarter_No,

    CAST(MONTH(Full_Date) AS tinyint) AS Month_No,

    CAST(
        CASE MONTH(Full_Date)
            WHEN 1 THEN N'January'
            WHEN 2 THEN N'February'
            WHEN 3 THEN N'March'
            WHEN 4 THEN N'April'
            WHEN 5 THEN N'May'
            WHEN 6 THEN N'June'
            WHEN 7 THEN N'July'
            WHEN 8 THEN N'August'
            WHEN 9 THEN N'September'
            WHEN 10 THEN N'October'
            WHEN 11 THEN N'November'
            WHEN 12 THEN N'December'
        END AS nvarchar(20)
    ) AS Month_Name,

    CAST(DAY(Full_Date) AS tinyint) AS Day_Of_Month

FROM CalendarDates;
GO


SELECT
    COUNT(*) AS Total_Dates,
    COUNT(DISTINCT Date_Key) AS Unique_Date_Keys,
    MIN(Full_Date) AS Start_Date,
    MAX(Full_Date) AS End_Date
FROM etl.vDate_Prepared;

SELECT TOP (5) *
FROM etl.vDate_Prepared
ORDER BY Full_Date;

