
USE master;
GO
IF DB_ID(N'HealthcareDW') IS NULL
    EXEC(N'CREATE DATABASE HealthcareDW');
GO
USE HealthcareDW;
GO
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;

 IF OBJECT_ID(N'dbo.DimSource',N'U') IS NULL
 CREATE TABLE dbo.DimSource (
  Source_Key int NOT NULL PRIMARY KEY,
  Source_Code varchar(10) NOT NULL UNIQUE,
  Source_Name nvarchar(150) NOT NULL
 );
 IF NOT EXISTS(SELECT 1 FROM dbo.DimSource WHERE Source_Key=1)
 INSERT dbo.DimSource VALUES(1,'EXCEL',N'City General Hospital');
 IF NOT EXISTS(SELECT 1 FROM dbo.DimSource WHERE Source_Key=2)
 INSERT dbo.DimSource VALUES(2,'CSV',N'Westside Community Clinic');

 IF OBJECT_ID(N'dbo.DimDate',N'U') IS NULL
 CREATE TABLE dbo.DimDate (
  Date_Key int NOT NULL PRIMARY KEY, -- YYYYMMDD; populate for ALL source dates
  Full_Date date NOT NULL UNIQUE,
  Calendar_Year smallint NOT NULL,
  Quarter_No tinyint NOT NULL CHECK(Quarter_No BETWEEN 1 AND 4),
  Month_No tinyint NOT NULL CHECK(Month_No BETWEEN 1 AND 12),
  Month_Name nvarchar(15) NOT NULL,
  Day_Of_Month tinyint NOT NULL CHECK(Day_Of_Month BETWEEN 1 AND 31)
 );

 IF OBJECT_ID(N'dbo.DimPatient',N'U') IS NULL
 CREATE TABLE dbo.DimPatient (
  Patient_Key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Code varchar(10) NOT NULL,
  Source_Patient_ID nvarchar(50) NOT NULL,
  Patient_Name nvarchar(250) NULL,
  Gender nvarchar(50) NULL,
  Date_Of_Birth date NULL,
  City nvarchar(150) NULL, -- Do not put a full CSV address in this field
  Blood_Group nvarchar(20) NULL,
  Insurance_Provider nvarchar(150) NULL,
  CONSTRAINT UQ_Patient_Source UNIQUE(Source_Code,Source_Patient_ID)
 );

 IF OBJECT_ID(N'dbo.DimDoctor',N'U') IS NULL
 CREATE TABLE dbo.DimDoctor (
  Doctor_Key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Code varchar(10) NOT NULL,
  Source_Doctor_ID nvarchar(50) NOT NULL,
  Doctor_Name nvarchar(250) NULL,
  Specialization nvarchar(150) NULL,
  Department_Name nvarchar(150) NULL, -- Look up Excel Departments in ETL
  Hospital_Branch nvarchar(150) NULL,
  CONSTRAINT UQ_Doctor_Source UNIQUE(Source_Code,Source_Doctor_ID)
 );

 IF OBJECT_ID(N'dbo.DimTreatmentType',N'U') IS NULL
 CREATE TABLE dbo.DimTreatmentType (
  Treatment_Type_Key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Code varchar(10) NOT NULL,
  Treatment_Type nvarchar(200) NOT NULL,
  CONSTRAINT UQ_TreatmentType UNIQUE(Source_Code,Treatment_Type)
 );

 IF OBJECT_ID(N'dbo.DimRoom',N'U') IS NULL
 CREATE TABLE dbo.DimRoom (
  Room_Key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Room_Type nvarchar(100) NOT NULL UNIQUE
 );

 IF OBJECT_ID(N'dbo.DimPayment',N'U') IS NULL
 CREATE TABLE dbo.DimPayment (
  Payment_Key int IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Code varchar(10) NOT NULL,
  Payment_Method nvarchar(100) NOT NULL,
  Payment_Status nvarchar(100) NOT NULL,
  CONSTRAINT UQ_Payment UNIQUE(Source_Code,Payment_Method,Payment_Status)
 );

 IF OBJECT_ID(N'dbo.FactAdmissions',N'U') IS NULL
 CREATE TABLE dbo.FactAdmissions (
  Admission_Key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Key int NOT NULL REFERENCES dbo.DimSource(Source_Key),
  Source_Admission_ID nvarchar(50) NOT NULL,
  Patient_Key int NOT NULL REFERENCES dbo.DimPatient(Patient_Key),
  Doctor_Key int NOT NULL REFERENCES dbo.DimDoctor(Doctor_Key),
  Admission_Date_Key int NOT NULL REFERENCES dbo.DimDate(Date_Key),
  Discharge_Date_Key int NULL REFERENCES dbo.DimDate(Date_Key),
  Room_Key int NULL REFERENCES dbo.DimRoom(Room_Key),
  Admission_Count tinyint NOT NULL DEFAULT(1) CHECK(Admission_Count=1),
  Length_Of_Stay_Days int NULL CHECK(Length_Of_Stay_Days>=0),
  CONSTRAINT UQ_Admission_Source UNIQUE(Source_Key,Source_Admission_ID)
 );

 IF OBJECT_ID(N'dbo.FactAppointments',N'U') IS NULL
 CREATE TABLE dbo.FactAppointments (
  Appointment_Key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Key int NOT NULL REFERENCES dbo.DimSource(Source_Key),
  Source_Appointment_ID nvarchar(50) NOT NULL,
  Patient_Key int NOT NULL REFERENCES dbo.DimPatient(Patient_Key),
  Doctor_Key int NOT NULL REFERENCES dbo.DimDoctor(Doctor_Key),
  Appointment_Date_Key int NOT NULL REFERENCES dbo.DimDate(Date_Key),
  Appointment_Time time NULL,
  Appointment_Status nvarchar(100) NULL,
  Appointment_Count tinyint NOT NULL DEFAULT(1) CHECK(Appointment_Count=1),
  CONSTRAINT UQ_Appointment_Source UNIQUE(Source_Key,Source_Appointment_ID)
 );

 IF OBJECT_ID(N'dbo.FactTreatments',N'U') IS NULL
 CREATE TABLE dbo.FactTreatments (
  Treatment_Key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Key int NOT NULL REFERENCES dbo.DimSource(Source_Key),
  Source_Treatment_ID nvarchar(50) NOT NULL,
  Source_Event_ID nvarchar(50) NOT NULL, -- Admission_ID or appointment_id
  Patient_Key int NOT NULL REFERENCES dbo.DimPatient(Patient_Key),
  Doctor_Key int NOT NULL REFERENCES dbo.DimDoctor(Doctor_Key),
  Treatment_Date_Key int NULL REFERENCES dbo.DimDate(Date_Key),
  Treatment_Type_Key int NOT NULL REFERENCES dbo.DimTreatmentType(Treatment_Type_Key),
  Treatment_Record_Count tinyint NOT NULL DEFAULT(1) CHECK(Treatment_Record_Count=1),
  Treatment_Cost decimal(19,4) NULL,
  Medicine_Cost decimal(19,4) NULL,
  Lab_Cost decimal(19,4) NULL,
  Currency_Code char(3) NULL,
  CONSTRAINT UQ_Treatment_Source UNIQUE(Source_Key,Source_Treatment_ID)
 );

 IF OBJECT_ID(N'dbo.FactBilling',N'U') IS NULL
 CREATE TABLE dbo.FactBilling (
  Billing_Key bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Source_Key int NOT NULL REFERENCES dbo.DimSource(Source_Key),
  Source_Bill_ID nvarchar(50) NOT NULL,
  Source_Admission_ID nvarchar(50) NULL,
  Source_Treatment_ID nvarchar(50) NULL,
  Patient_Key int NOT NULL REFERENCES dbo.DimPatient(Patient_Key),
  Doctor_Key int NOT NULL REFERENCES dbo.DimDoctor(Doctor_Key),
  Bill_Date_Key int NULL REFERENCES dbo.DimDate(Date_Key),
  Payment_Key int NOT NULL REFERENCES dbo.DimPayment(Payment_Key),
  Bill_Count tinyint NOT NULL DEFAULT(1) CHECK(Bill_Count=1),
  Bill_Amount decimal(19,4) NULL, -- Excel Total_Bill / CSV amount; compare only after semantic validation
  Insurance_Cover decimal(19,4) NULL,
  Final_Amount_Payable decimal(19,4) NULL,
  EMI_Months int NULL,
  Monthly_EMI decimal(19,4) NULL, -- Per-bill instalment; NOT a monthly revenue measure
  Currency_Code char(3) NULL,
  CONSTRAINT UQ_Billing_Source UNIQUE(Source_Key,Source_Bill_ID)
 );

 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
-- Verification 1: expected 11 application tables (7 dimensions, 4 facts).
SELECT name AS Table_Name FROM sys.tables
WHERE schema_id=SCHEMA_ID('dbo') AND (name LIKE 'Dim%' OR name LIKE 'Fact%')
ORDER BY name;
-- Verification 2: expected 11 primary keys.
SELECT OBJECT_NAME(parent_object_id) AS Table_Name,name AS Primary_Key
FROM sys.key_constraints WHERE type='PK' ORDER BY Table_Name;
-- Verification 3: expected 20 foreign keys; enabled and trusted.
SELECT OBJECT_NAME(parent_object_id) AS Fact_Table,
       OBJECT_NAME(referenced_object_id) AS Dimension_Table,
       name AS Foreign_Key,is_disabled,is_not_trusted
FROM sys.foreign_keys ORDER BY Fact_Table,Dimension_Table;
-- Only DimSource has records at this stage. These are project labels, not real data.
SELECT * FROM dbo.DimSource;
GO


select *
from 