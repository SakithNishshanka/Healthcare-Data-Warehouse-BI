USE HealthcareDW;
GO

WITH Categories AS (
    SELECT
        N'EXCEL' AS Source_Code,
        N'Room_Type' AS Field_Name,
        CONVERT(nvarchar(500), Room_Type) AS Raw_Value
    FROM stg.Excel_Admissions

    UNION ALL
    SELECT N'EXCEL', N'Treatment_Type',
           CONVERT(nvarchar(500), Treatment_Type)
    FROM stg.Excel_Treatment

    UNION ALL
    SELECT N'CSV', N'Treatment_Type',
           CONVERT(nvarchar(500), treatment_type)
    FROM stg.CSV_Treatments

    UNION ALL
    SELECT N'EXCEL', N'Payment_Method',
           CONVERT(nvarchar(500), Payment_Mode)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT N'CSV', N'Payment_Method',
           CONVERT(nvarchar(500), payment_method)
    FROM stg.CSV_Billing

    UNION ALL
    SELECT N'EXCEL', N'Payment_Status',
           CONVERT(nvarchar(500), Payment_Status)
    FROM stg.Excel_Billing

    UNION ALL
    SELECT N'CSV', N'Payment_Status',
           CONVERT(nvarchar(500), payment_status)
    FROM stg.CSV_Billing
),
CleanCategories AS (
    SELECT
        Source_Code,
        Field_Name,
        NULLIF(LTRIM(RTRIM(Raw_Value)), N'') AS Category_Value
    FROM Categories
)
SELECT
    Source_Code,
    Field_Name,
    Category_Value,
    COUNT(*) AS Record_Count
FROM CleanCategories
GROUP BY Source_Code, Field_Name, Category_Value
ORDER BY Field_Name, Source_Code, Category_Value;