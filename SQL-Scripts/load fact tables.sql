USE HealthcareDW;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- EMI months must be a whole number that fits an int.
    IF EXISTS (
        SELECT 1
        FROM etl.vBilling_Prepared
        WHERE EMI_Months IS NOT NULL
          AND (
              EMI_Months <> FLOOR(EMI_Months)
              OR TRY_CONVERT(int, EMI_Months) IS NULL
          )
    )
    BEGIN
        THROW 50010, 'Invalid EMI months: investigate before loading.', 1;
    END;


    -- A. ADMISSIONS
    INSERT INTO dbo.FactAdmissions (
        Source_Key,
        Source_Admission_ID,
        Patient_Key,
        Doctor_Key,
        Admission_Date_Key,
        Discharge_Date_Key,
        Room_Key,
        Admission_Count,
        Length_Of_Stay_Days
    )
    SELECT
        s.Source_Key,
        v.Source_Admission_ID,
        p.Patient_Key,
        d.Doctor_Key,
        v.Admission_Date_Key,
        v.Discharge_Date_Key,
        r.Room_Key,
        v.Admission_Count,
        v.Length_Of_Stay_Days
    FROM etl.vAdmissions_Prepared AS v
    JOIN dbo.DimSource AS s
        ON s.Source_Code = v.Source_Code
    JOIN dbo.DimPatient AS p
        ON p.Source_Code = v.Source_Code
       AND p.Source_Patient_ID = v.Source_Patient_ID
    JOIN dbo.DimDoctor AS d
        ON d.Source_Code = v.Source_Code
       AND d.Source_Doctor_ID = v.Source_Doctor_ID
    JOIN dbo.DimRoom AS r
        ON r.Room_Type = v.Room_Type
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.FactAdmissions AS f
        WHERE f.Source_Key = s.Source_Key
          AND f.Source_Admission_ID = v.Source_Admission_ID
    );


    -- B. APPOINTMENTS
    INSERT INTO dbo.FactAppointments (
        Source_Key,
        Source_Appointment_ID,
        Patient_Key,
        Doctor_Key,
        Appointment_Date_Key,
        Appointment_Time,
        Appointment_Status,
        Appointment_Count
    )
    SELECT
        s.Source_Key,
        v.Source_Appointment_ID,
        p.Patient_Key,
        d.Doctor_Key,
        v.Appointment_Date_Key,
        v.Appointment_Time,
        v.Appointment_Status,
        v.Appointment_Count
    FROM etl.vAppointments_Prepared AS v
    JOIN dbo.DimSource AS s
        ON s.Source_Code = v.Source_Code
    JOIN dbo.DimPatient AS p
        ON p.Source_Code = v.Source_Code
       AND p.Source_Patient_ID = v.Source_Patient_ID
    JOIN dbo.DimDoctor AS d
        ON d.Source_Code = v.Source_Code
       AND d.Source_Doctor_ID = v.Source_Doctor_ID
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.FactAppointments AS f
        WHERE f.Source_Key = s.Source_Key
          AND f.Source_Appointment_ID = v.Source_Appointment_ID
    );


    -- C. TREATMENTS
    INSERT INTO dbo.FactTreatments (
        Source_Key,
        Source_Treatment_ID,
        Source_Event_ID,
        Patient_Key,
        Doctor_Key,
        Treatment_Date_Key,
        Treatment_Type_Key,
        Treatment_Record_Count,
        Treatment_Cost,
        Medicine_Cost,
        Lab_Cost,
        Currency_Code
    )
    SELECT
        s.Source_Key,
        v.Source_Treatment_ID,

        CASE
            WHEN v.Source_Code = N'EXCEL'
                THEN v.Source_Admission_ID
            WHEN v.Source_Code = N'CSV'
                THEN v.Source_Appointment_ID
        END,

        p.Patient_Key,
        d.Doctor_Key,
        v.Treatment_Date_Key,
        t.Treatment_Type_Key,
        v.Treatment_Count,
        v.Treatment_Cost,
        v.Medicine_Cost,
        v.Lab_Cost,
        NULL
    FROM etl.vTreatments_Prepared AS v
    JOIN dbo.DimSource AS s
        ON s.Source_Code = v.Source_Code
    JOIN dbo.DimPatient AS p
        ON p.Source_Code = v.Source_Code
       AND p.Source_Patient_ID = v.Source_Patient_ID
    JOIN dbo.DimDoctor AS d
        ON d.Source_Code = v.Source_Code
       AND d.Source_Doctor_ID = v.Source_Doctor_ID
    JOIN dbo.DimTreatmentType AS t
        ON t.Source_Code = v.Source_Code
       AND t.Treatment_Type = v.Treatment_Type
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.FactTreatments AS f
        WHERE f.Source_Key = s.Source_Key
          AND f.Source_Treatment_ID = v.Source_Treatment_ID
    );


    -- D. BILLING
    INSERT INTO dbo.FactBilling (
        Source_Key,
        Source_Bill_ID,
        Source_Admission_ID,
        Source_Treatment_ID,
        Patient_Key,
        Doctor_Key,
        Bill_Date_Key,
        Payment_Key,
        Bill_Count,
        Bill_Amount,
        Insurance_Cover,
        Final_Amount_Payable,
        EMI_Months,
        Monthly_EMI,
        Currency_Code
    )
    SELECT
        s.Source_Key,
        v.Source_Bill_ID,
        v.Source_Admission_ID,
        v.Source_Treatment_ID,
        p.Patient_Key,
        d.Doctor_Key,
        v.Bill_Date_Key,
        pay.Payment_Key,
        v.Bill_Count,
        v.Bill_Amount,
        v.Insurance_Cover,
        v.Final_Amount_Payable,
        CONVERT(int, v.EMI_Months),
        v.Monthly_EMI,
        NULL
    FROM etl.vBilling_Prepared AS v
    JOIN dbo.DimSource AS s
        ON s.Source_Code = v.Source_Code
    JOIN dbo.DimPatient AS p
        ON p.Source_Code = v.Source_Code
       AND p.Source_Patient_ID = v.Source_Patient_ID
    JOIN dbo.DimDoctor AS d
        ON d.Source_Code = v.Source_Code
       AND d.Source_Doctor_ID = v.Source_Doctor_ID
    JOIN dbo.DimPayment AS pay
        ON pay.Source_Code = v.Source_Code
       AND pay.Payment_Method = v.Payment_Method
       AND pay.Payment_Status = v.Payment_Status
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.FactBilling AS f
        WHERE f.Source_Key = s.Source_Key
          AND f.Source_Bill_ID = v.Source_Bill_ID
    );


    -- E. Ensure no prepared records were missed by the joins.
    IF EXISTS (
        SELECT v.Source_Code, v.Source_Admission_ID
        FROM etl.vAdmissions_Prepared AS v
        EXCEPT
        SELECT s.Source_Code, f.Source_Admission_ID
        FROM dbo.FactAdmissions AS f
        JOIN dbo.DimSource AS s
            ON s.Source_Key = f.Source_Key
    )
    BEGIN
        THROW 50011, 'Some admissions were not loaded.', 1;
    END;

    IF EXISTS (
        SELECT v.Source_Code, v.Source_Appointment_ID
        FROM etl.vAppointments_Prepared AS v
        EXCEPT
        SELECT s.Source_Code, f.Source_Appointment_ID
        FROM dbo.FactAppointments AS f
        JOIN dbo.DimSource AS s
            ON s.Source_Key = f.Source_Key
    )
    BEGIN
        THROW 50012, 'Some appointments were not loaded.', 1;
    END;

    IF EXISTS (
        SELECT v.Source_Code, v.Source_Treatment_ID
        FROM etl.vTreatments_Prepared AS v
        EXCEPT
        SELECT s.Source_Code, f.Source_Treatment_ID
        FROM dbo.FactTreatments AS f
        JOIN dbo.DimSource AS s
            ON s.Source_Key = f.Source_Key
    )
    BEGIN
        THROW 50013, 'Some treatments were not loaded.', 1;
    END;

    IF EXISTS (
        SELECT v.Source_Code, v.Source_Bill_ID
        FROM etl.vBilling_Prepared AS v
        EXCEPT
        SELECT s.Source_Code, f.Source_Bill_ID
        FROM dbo.FactBilling AS f
        JOIN dbo.DimSource AS s
            ON s.Source_Key = f.Source_Key
    )
    BEGIN
        THROW 50014, 'Some bills were not loaded.', 1;
    END;

    COMMIT TRANSACTION;

    SELECT N'FACT_LOAD_COMPLETED' AS Load_Status;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO



SELECT
    N'Admissions' AS Fact_Table,
    s.Source_Code,
    COUNT(*) AS Loaded_Rows
FROM dbo.FactAdmissions AS f
JOIN dbo.DimSource AS s ON s.Source_Key = f.Source_Key
GROUP BY s.Source_Code

UNION ALL

SELECT N'Appointments', s.Source_Code, COUNT(*)
FROM dbo.FactAppointments AS f
JOIN dbo.DimSource AS s ON s.Source_Key = f.Source_Key
GROUP BY s.Source_Code

UNION ALL

SELECT N'Treatments', s.Source_Code, COUNT(*)
FROM dbo.FactTreatments AS f
JOIN dbo.DimSource AS s ON s.Source_Key = f.Source_Key
GROUP BY s.Source_Code

UNION ALL

SELECT N'Billing', s.Source_Code, COUNT(*)
FROM dbo.FactBilling AS f
JOIN dbo.DimSource AS s ON s.Source_Key = f.Source_Key
GROUP BY s.Source_Code;