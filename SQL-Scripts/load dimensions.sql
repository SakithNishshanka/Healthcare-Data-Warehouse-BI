USE HealthcareDW;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Confirm the two source records created in Task 4.
    IF (
        SELECT COUNT(*)
        FROM dbo.DimSource
        WHERE Source_Code IN ('EXCEL', 'CSV')
    ) <> 2
    BEGIN
        THROW 50001,
            'DimSource must contain one EXCEL and one CSV record.',
            1;
    END;

    -- Confirm the patient preparation preserves all source rows.
    IF (SELECT COUNT(*) FROM etl.vPatient_LoadReady)
       <> (
           (SELECT COUNT(*) FROM stg.Excel_Patients)
           + (SELECT COUNT(*) FROM stg.CSV_Patients)
       )
    BEGIN
        THROW 50002, 'Prepared patient count does not match staging.', 1;
    END;


    -- A. DATE
    -- Refresh attributes for existing date keys.
    UPDATE d
    SET
        Full_Date = v.Full_Date,
        Calendar_Year = v.Calendar_Year,
        Quarter_No = v.Quarter_No,
        Month_No = v.Month_No,
        Month_Name = v.Month_Name,
        Day_Of_Month = v.Day_Of_Month
    FROM dbo.DimDate AS d
    JOIN etl.vDate_Prepared AS v
        ON d.Date_Key = v.Date_Key;

    INSERT INTO dbo.DimDate (
        Date_Key,
        Full_Date,
        Calendar_Year,
        Quarter_No,
        Month_No,
        Month_Name,
        Day_Of_Month
    )
    SELECT
        v.Date_Key,
        v.Full_Date,
        v.Calendar_Year,
        v.Quarter_No,
        v.Month_No,
        v.Month_Name,
        v.Day_Of_Month
    FROM etl.vDate_Prepared AS v
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DimDate AS d
        WHERE d.Date_Key = v.Date_Key
    );


    -- B. PATIENT: Type 1 updates
    UPDATE d
    SET
        Patient_Name = v.Patient_Name,
        Gender = v.Gender,
        Date_Of_Birth = v.Date_of_Birth,
        City = v.City,
        Blood_Group = v.Blood_Group,
        Insurance_Provider = v.Insurance_Provider
    FROM dbo.DimPatient AS d
    JOIN etl.vPatient_LoadReady AS v
        ON d.Source_Code = v.Source_Code
       AND d.Source_Patient_ID = v.Source_Patient_ID;

    INSERT INTO dbo.DimPatient (
        Source_Code,
        Source_Patient_ID,
        Patient_Name,
        Gender,
        Date_Of_Birth,
        City,
        Blood_Group,
        Insurance_Provider
    )
    SELECT
        v.Source_Code,
        v.Source_Patient_ID,
        v.Patient_Name,
        v.Gender,
        v.Date_of_Birth,
        v.City,
        v.Blood_Group,
        v.Insurance_Provider
    FROM etl.vPatient_LoadReady AS v
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DimPatient AS d
        WHERE d.Source_Code = v.Source_Code
          AND d.Source_Patient_ID = v.Source_Patient_ID
    );


    -- C. DOCTOR: use the validated specialization field
        -- C1. DEPARTMENT: update existing departments
    UPDATE dep
    SET
        Department_Name =
            NULLIF(LTRIM(RTRIM(s.Department_Name)), N''),
        Floor_Number = CONVERT(INT, s.Floor_Number)
    FROM dbo.DimDepartment AS dep
    INNER JOIN stg.Excel_Departments AS s
        ON dep.Source_Code = N'EXCEL'
       AND dep.Source_Department_ID =
           LTRIM(RTRIM(CONVERT(NVARCHAR(500), s.Department_ID)));


    -- Insert new departments
    INSERT INTO dbo.DimDepartment
    (
        Source_Code,
        Source_Department_ID,
        Department_Name,
        Floor_Number
    )
    SELECT
        N'EXCEL',
        LTRIM(RTRIM(CONVERT(NVARCHAR(500), s.Department_ID))),
        NULLIF(LTRIM(RTRIM(s.Department_Name)), N''),
        CONVERT(INT, s.Floor_Number)
    FROM stg.Excel_Departments AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.DimDepartment AS dep
        WHERE dep.Source_Code = N'EXCEL'
          AND dep.Source_Department_ID =
              LTRIM(RTRIM(CONVERT(NVARCHAR(500), s.Department_ID)))
    );


    -- C2. Validate department mapping before loading doctors
    IF EXISTS
    (
        SELECT 1
        FROM etl.vDoctor_Validated AS v
        LEFT JOIN dbo.DimDepartment AS dep
            ON dep.Source_Code = v.Source_Code
           AND dep.Source_Department_ID = v.Source_Department_ID
        WHERE v.Source_Code = N'EXCEL'
          AND dep.Department_Key IS NULL
    )
    BEGIN
        THROW 50003,
            'An Excel doctor has no matching department. Check source IDs.',
            1;
    END;


    -- C3. DOCTOR: update existing doctors
    UPDATE d
    SET
        Doctor_Name = v.Doctor_Name,
        Specialization = v.Specialization,
        Department_Key = dep.Department_Key,
        Hospital_Branch = v.Hospital_Branch
    FROM dbo.DimDoctor AS d
    INNER JOIN etl.vDoctor_Validated AS v
        ON d.Source_Code = v.Source_Code
       AND d.Source_Doctor_ID = v.Source_Doctor_ID
    LEFT JOIN dbo.DimDepartment AS dep
        ON dep.Source_Code = v.Source_Code
       AND dep.Source_Department_ID = v.Source_Department_ID;


    -- Insert new doctors
    INSERT INTO dbo.DimDoctor
    (
        Source_Code,
        Source_Doctor_ID,
        Doctor_Name,
        Specialization,
        Department_Key,
        Hospital_Branch
    )
    SELECT
        v.Source_Code,
        v.Source_Doctor_ID,
        v.Doctor_Name,
        v.Specialization,
        dep.Department_Key,
        v.Hospital_Branch
    FROM etl.vDoctor_Validated AS v
    LEFT JOIN dbo.DimDepartment AS dep
        ON dep.Source_Code = v.Source_Code
       AND dep.Source_Department_ID = v.Source_Department_ID
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.DimDoctor AS d
        WHERE d.Source_Code = v.Source_Code
          AND d.Source_Doctor_ID = v.Source_Doctor_ID
    );

    -- D. ROOM
    INSERT INTO dbo.DimRoom (Room_Type)
    SELECT v.Room_Type
    FROM etl.vRoom_Prepared AS v
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DimRoom AS d
        WHERE d.Room_Type = v.Room_Type
    );


    -- E. TREATMENT TYPE
    INSERT INTO dbo.DimTreatmentType (
        Source_Code,
        Treatment_Type
    )
    SELECT
        v.Source_Code,
        v.Treatment_Type
    FROM etl.vTreatmentType_Prepared AS v
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DimTreatmentType AS d
        WHERE d.Source_Code = v.Source_Code
          AND d.Treatment_Type = v.Treatment_Type
    );


    -- F. PAYMENT
    INSERT INTO dbo.DimPayment (
        Source_Code,
        Payment_Method,
        Payment_Status
    )
    SELECT
        v.Source_Code,
        v.Payment_Method,
        v.Payment_Status
    FROM etl.vPayment_Prepared AS v
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DimPayment AS d
        WHERE d.Source_Code = v.Source_Code
          AND d.Payment_Method = v.Payment_Method
          AND d.Payment_Status = v.Payment_Status
    );

    COMMIT TRANSACTION;

    SELECT N'DIMENSION_LOAD_COMPLETED' AS Load_Status;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO



-- Compare prepared counts with destination counts.
SELECT
    N'DimSource' AS Table_Name,
    2 AS Expected_Rows,
    COUNT(*) AS Actual_Rows
FROM dbo.DimSource

UNION ALL
SELECT N'DimDate',
       (SELECT COUNT(*) FROM etl.vDate_Prepared),
       COUNT(*)
FROM dbo.DimDate

UNION ALL
SELECT N'DimPatient',
       (SELECT COUNT(*) FROM etl.vPatient_LoadReady),
       COUNT(*)
FROM dbo.DimPatient

UNION ALL
SELECT N'DimDoctor',
       (SELECT COUNT(*) FROM etl.vDoctor_Validated),
       COUNT(*)
FROM dbo.DimDoctor

UNION ALL
SELECT N'DimRoom',
       (SELECT COUNT(*) FROM etl.vRoom_Prepared),
       COUNT(*)
FROM dbo.DimRoom

UNION ALL
SELECT N'DimTreatmentType',
       (SELECT COUNT(*) FROM etl.vTreatmentType_Prepared),
       COUNT(*)
FROM dbo.DimTreatmentType

UNION ALL
SELECT N'DimPayment',
       (SELECT COUNT(*) FROM etl.vPayment_Prepared),
       COUNT(*)
FROM dbo.DimPayment

UNION ALL
SELECT N'DimDepartment',
       (SELECT COUNT(*) FROM stg.Excel_Departments),
       COUNT(*)
FROM dbo.DimDepartment;


-- Verify patient and doctor counts by source.
SELECT
    N'Patient' AS Entity,
    Source_Code,
    COUNT(*) AS Record_Count
FROM dbo.DimPatient
GROUP BY Source_Code

UNION ALL

SELECT
    N'Doctor',
    Source_Code,
    COUNT(*)
FROM dbo.DimDoctor
GROUP BY Source_Code;


-- Verify specialization handling.
SELECT
    Source_Code,
    COUNT(*) AS Doctor_Count,
    COUNT(Specialization) AS Available_Specializations
FROM dbo.DimDoctor
GROUP BY Source_Code;

