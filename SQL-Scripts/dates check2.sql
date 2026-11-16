USE HealthcareDW;
GO

WITH NumericValues AS (
    SELECT 'Excel_Doctors.Consultation_Fee' AS Field_Name,
           CONVERT(nvarchar(500), Consultation_Fee) AS Raw_Value
    FROM stg.Excel_Doctors

    UNION ALL
    SELECT 'Excel_Treatment.Treatment_Cost',
           CONVERT(nvarchar(500), Treatment_Cost)
    FROM stg.Excel_Treatment

    UNION ALL
    SELECT 'Excel_Treatment.Medicine_Cost',
           CONVERT(nvarchar(500), Medicine_Cost)
    FROM stg.Excel_Treatment

    UNION ALL
    SELECT 'Excel_Treatment.Lab_Cost',
           CONVERT(nvarchar(500), Lab_Cost)
    FROM stg.Excel_Treatment

    UNION ALL
    SELECT 'Excel_Billing.Total_Bill',
           CONVERT(nvarchar(500), Total_Bill)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT 'Excel_Billing.Insurance_Cover',
           CONVERT(nvarchar(500), Insurance_Cover)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT 'Excel_Billing.Final_Amount_Payable',
           CONVERT(nvarchar(500), Final_Amount_Payable)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT 'Excel_Billing.EMI_Months',
           CONVERT(nvarchar(500), EMI_Months)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT 'Excel_Billing.Monthly_EMI',
           CONVERT(nvarchar(500), Monthly_EMI)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT 'CSV_Doctors.years_experience',
           CONVERT(nvarchar(500), years_experience)
    FROM stg.CSV_Doctors

    UNION ALL
    SELECT 'CSV_Treatments.cost',
           CONVERT(nvarchar(500), cost)
    FROM stg.CSV_Treatments

    UNION ALL
    SELECT 'CSV_Billing.amount',
           CONVERT(nvarchar(500), amount)
    FROM stg.CSV_Billing
),
CleanValues AS (
    SELECT
        Field_Name,
        NULLIF(LTRIM(RTRIM(Raw_Value)), '') AS Clean_Value
    FROM NumericValues
),
ConvertedValues AS (
    SELECT
        Field_Name,
        Clean_Value,
        TRY_CONVERT(decimal(28,6), Clean_Value) AS Numeric_Value
    FROM CleanValues
)
SELECT
    Field_Name,
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Clean_Value IS NULL
             THEN 1 ELSE 0 END) AS Missing_Values,
    SUM(CASE WHEN Clean_Value IS NOT NULL
                  AND Numeric_Value IS NULL
             THEN 1 ELSE 0 END) AS Invalid_Values,
    SUM(CASE WHEN Numeric_Value < 0
             THEN 1 ELSE 0 END) AS Negative_Values
FROM ConvertedValues
GROUP BY Field_Name
ORDER BY Field_Name;



SELECT COUNT(*) AS Discharge_Before_Admission
FROM stg.Excel_Admissions
WHERE TRY_CONVERT(datetime2, Discharge_Date, 120)
    < TRY_CONVERT(datetime2, Admission_Date, 120);