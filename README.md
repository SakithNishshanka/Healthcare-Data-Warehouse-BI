# 🏥 Healthcare Data Warehouse & Business Intelligence

### 📊 End-to-End Healthcare Analytics Using SQL Server, SSMS & Power BI

![SQL Server](https://img.shields.io/badge/SQL%20Server-Data%20Warehouse-CC2927?logo=microsoftsqlserver&logoColor=white) ![Power BI](https://img.shields.io/badge/Power%20BI-Interactive%20Dashboards-F2C811?logo=powerbi&logoColor=black) ![SQL](https://img.shields.io/badge/SQL-ETL%20%26%20OLAP-336791) ![License](https://img.shields.io/badge/License-MIT-green)

## 🔎 Project Overview

This project designs and implements a **healthcare data warehouse and business intelligence solution** using **Microsoft SQL Server, SQL Server Management Studio (SSMS), and Power BI**. It integrates hospital inpatient records and clinic appointment records into a unified analytical environment, with source-specific business processes retained at their appropriate grain.

The solution supports analysis of **admissions, patients, doctors, departments, room utilization patterns, and length of stay**. An admissions-focused data mart powers three interactive Power BI report pages for operational decision-making.

> **Dataset note:** The hospital and clinic names used in the project are illustrative labels, not verified data publishers. The source datasets are publicly listed on Kaggle; they should not be interpreted as live clinical records.

## 🎯 Project Objectives

- Integrate Excel and CSV operational data sources.
- Build a dimensional data warehouse with shared dimensions and multiple fact tables.
- Implement SQL-based staging, cleansing, transformations, and data loading.
- Create a department-focused admissions and operations data mart.
- Validate data quality, keys, relationships, and dashboard measures.
- Deliver interactive dashboards and evidence-based healthcare operations insights.

## 🛠️ Technology Stack

| Technology | Role |
|---|---|
| Microsoft SQL Server | Relational storage and analytical warehouse |
| SQL Server Management Studio (SSMS) | Database development, SQL ETL, testing and validation |
| T-SQL | Schema creation, transformations, views, facts and dimensions |
| Power BI Desktop | Data modeling, DAX measures and interactive reporting |
| Excel and CSV | Operational data sources |

## 📂 Data Sources

The project uses two operational source groups:

| Source | Format | Contents |
|---|---|---|
| Hospital management dataset | Excel workbook | Patients, doctors, departments, admissions, treatments, billing and calendar |
| Clinic management dataset | Five CSV files | Patients, doctors, appointments, treatments and billing |

The hospital workbook includes **50,000 admissions**, **50,000 treatment records**, **50,000 bills**, **10,000 patient records**, and **200 doctors**. The clinic source includes **200 appointments**, **200 treatments**, and **200 bills**.

**Dataset references:**
- [Hospital Management Dataset — Kaggle](https://www.kaggle.com/datasets/garimakochale/hospital-management-dataset)
- [Hospital Management Dataset — Kaggle](https://www.kaggle.com/datasets/kanakbaghel/hospital-management-dataset)

## 🏗️ Solution Architecture

```text
Operational Sources
  |-- Hospital Excel workbook
  `-- Clinic CSV files
           |
           v
SQL Server Staging Layer
           |
           v
SQL ETL (Extract -> Clean -> Transform -> Load)
           |
           v
Healthcare Data Warehouse
  |-- Shared dimensions
  |-- Admissions fact
  |-- Appointments fact
  |-- Treatments fact
  `-- Billing fact
           |
           v
Admissions & Operations Data Mart (SQL Views)
           |
           v
Power BI Analytical Model
  |-- Executive Summary
  |-- Trend Analysis
  `-- Interactive Analysis
```

## 🧩 Dimensional Data Model

The warehouse uses a **fact constellation** with shared dimensions. Its fact-to-dimension relationships form star structures; the department relationship through the doctor dimension introduces a snowflake branch.

### 📈 Fact Tables

| Fact | Grain | Main measures |
|---|---|---|
| `FactAdmissions` | One hospital admission | Admission count, length of stay |
| `FactAppointments` | One clinic appointment | Appointment count |
| `FactTreatments` | One source treatment record | Treatment count, treatment cost, medicine cost, lab cost |
| `FactBilling` | One source bill | Bill count, bill amount, insurance cover, final payable |

### 🗂️ Dimension Tables

`DimSource`, `DimPatient`, `DimDoctor`, `DimDepartment`, `DimDate`, `DimRoom`, `DimTreatmentType`, and `DimPayment`.

Source-specific business identifiers are retained to avoid conflating records from different systems. Surrogate keys support warehouse relationships.

![Power BI Data Model](screenshots/model%20view.png)

*Warehouse relationships displayed in the Power BI model view.*

## ⚙️ ETL Implementation in SSMS

The SQL scripts implement the following workflow:

1. **Extract:** Load hospital Excel and clinic CSV data into SQL Server staging tables.
2. **Transform:** Check categorical values, validate dates, standardize attributes, create patient and doctor transformation views, and prepare dimension mappings.
3. **Load:** Populate dimension tables before fact tables to preserve referential integrity.
4. **Validate:** Check staging counts, duplicate records, foreign keys, relationships, and KPI calculations.
5. **Serve:** Create admissions-oriented data mart views for Power BI consumption.

Key scripts in the supplied project include:

- `create db and tables.sql`
- `create stg schema.sql`
- `check and clean categorical values.sql`
- `create patient view and transformation.sql`
- `transform doctors.sql`
- `load dimensions.sql`
- `load fact tables.sql`
- `create admission data mart.sql`
- `kpi check.sql`

![Staging Tables](screenshots/Staging%20tables.png)

## 🏥 Admissions & Operations Data Mart

The admissions data mart is implemented through **seven SQL views: one fact view and six dimension views**. Power BI imports these views from the `HealthcareDW` database. Department filters propagate through doctors to admissions, while other dimensions filter admissions directly.


## 📊 Power BI Dashboard

> 🖥️ **Dashboard preview:** [View the exported Power BI report (PDF)](powerBI/Healthcare_Admissions_Dashboard_update_final.pdf) · [Open the interactive Power BI file](powerBI/Healthcare_Admissions_Dashboard_update_final.pbix)

The Power BI solution includes **three analytical report pages**.

### 1. 📌 Executive Summary

Four KPI cards summarize admission activity (with report filters cleared):

| KPI | Result |
|---|---:|
| Total Admissions | **50,000** |
| Unique Patients | **9,927** |
| Doctors With Admissions | **200** |
| Average Length of Stay | **7.46 days** |

### 2. 📉 Trend Analysis

- Monthly admissions trend.
- Average length of stay by admission month.
- Admissions by year and room type.
- Year-based filtering for time comparisons.

### 3. 🔍 Interactive Analysis

- Slicers for **year, department, room type, and gender**.
- Department-to-doctor drill-down and roll-up.
- Decomposition tree for admissions by gender, department, room type, and city.
- City-level comparison of unique patients.

> To preview the complete report without Power BI Desktop, open the exported PDF in the `powerBI` folder. To explore the interactive model, open `Healthcare_Admissions_Dashboard_update_final.pbix` in Power BI Desktop.

## 💡 Key Business Insights

| Finding | Implication |
|---|---|
| **Oncology** has the highest admission count; **Gastroenterology** has the lowest. | Review department-level staffing and resource requirements. |
| General rooms account for **29,947 admissions (59.89%)**, private rooms for **14,918 (29.84%)**, and ICU for **5,135 (10.27%)**. | Inform room-specific staffing and supply planning; occupancy requires separate bed-capacity data. |
| Average length of stay is **7.46 days**. | Compare stay durations by department and room type. |
| **50,000 admissions** involve **9,927 unique patients**. | Explore repeat admissions and follow-up needs; this is not itself a 30-day readmission rate. |
| Male admissions total **25,041 (50.08%)** and female admissions **24,959 (49.92%)**. | Investigate whether patterns differ by department. |
| **North Michael** leads the displayed city chart for unique patients. | Review geographic demand before planning outreach. |

These observations are based on the project's supplied dataset and report; they are not claims about real-world hospital performance.

## 📁 Repository Structure

The following layout assumes the uploaded files are organized into the folders shown. Update folder names or links if your repository uses different paths.

```text
Healthcare-Data-Warehouse-BI/
|-- Query/                  # SQL scripts: schema, ETL, views, validation
|-- powerBI/
|   |-- Healthcare_Admissions_Dashboard.pbix
|-- raw data/               # Source datasets, if redistribution is permitted
|-- screenshots/            # SSMS, dimensional model and data mart evidence
|-- report/                 # Project documentation
|-- README.md
`-- LICENSE
```

## 🚀 How to Explore or Reproduce the Project

1. Install **Microsoft SQL Server**, **SSMS**, and **Power BI Desktop**.
2. Review the SQL scripts in `Query/` and the source-file paths used by the loading process.
3. Create the database and staging objects, then import the authorized Excel/CSV source data.
4. Execute the transformation and dimension/fact loading scripts in dependency order.
5. Run the validation queries and create the admissions data mart views.
6. Open the final `.pbix` report in Power BI Desktop.
7. Update the SQL Server connection settings to your own local environment, refresh the model, and verify KPI totals.

**Note:** These are workflow-level reproduction instructions. Local file paths, SQL Server permissions, and source-loading configuration may require adjustments. Do not commit credentials to GitHub.

## 📄 Project Documentation

See the report folder for the complete assignment documentation, architecture decisions, SQL implementation evidence, data model, dashboard explanation, and business recommendations.

## 🔒 Responsible Data Use

This repository is intended as an educational and portfolio project. Do not upload patient-identifying information, private credentials, or datasets without redistribution permission. The MIT License covers original project material that the repository owner is authorized to license; third-party datasets retain their own terms.

## 📜 License

Original code in this repository is provided under the [MIT License](LICENSE), subject to the rights of the respective authors and data providers.
