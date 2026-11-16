USE HealthcareDW;
GO

SELECT TOP (5)
    Date_of_Birth
FROM stg.Excel_Patients;

SELECT TOP (5)
    Admission_Date,
    Discharge_Date
FROM stg.Excel_Admissions;

SELECT TOP (5)
    [Date]
FROM stg.Excel_Calendar;

SELECT TOP (5)
    date_of_birth,
    registration_date
FROM stg.CSV_Patients;

SELECT TOP (5)
    appointment_date,
    appointment_time
FROM stg.CSV_Appointments;

SELECT TOP (5)
    treatment_date,
    cost
FROM stg.CSV_Treatments;

SELECT TOP (5)
    bill_date,
    amount
FROM stg.CSV_Billing;


