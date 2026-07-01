===========================================================================
   EMERGENCY OPERATIONS & PATIENT FLOW — OPERATIONAL & PREDICTIVE ANALYSIS
   ----------------------------------------------------------------------------
   Database : HospitalAnalytics  |  Table: dbo.Patient_Visits (~10,000 rows)
   Story    : Setup → Data Quality → Operational Performance (hospital /
              department / flow / outcomes / satisfaction / cost) →
              Predictive Models (mortality / readmission / LOS / ICU /
              volume / satisfaction) → Composite Risk Scoring → Validation
   ============================================================================ */


/* ============================================================================
   SECTION 1 — SETUP & DATA IMPORT
   ============================================================================ */

IF DB_ID('HospitalAnalytics') IS NULL
    CREATE DATABASE HospitalAnalytics;
GO

USE HospitalAnalytics;
GO

IF OBJECT_ID('dbo.Patient_Visits', 'U') IS NOT NULL
    DROP TABLE dbo.Patient_Visits;
GO

-- Table mirrors CSV structure; nullable columns reflect real data gaps.
CREATE TABLE dbo.Patient_Visits (
    Visit_ID                    VARCHAR(15)     PRIMARY KEY,
    Patient_ID                  VARCHAR(15)     NOT NULL,
    Hospital_ID                 VARCHAR(10)     NOT NULL,
    Department_ID               VARCHAR(10)     NOT NULL,
    Doctor_ID                   VARCHAR(15)     NOT NULL,
    Arrival_DateTime            DATETIME2       NOT NULL,
    Triage_DateTime             DATETIME2       NULL,
    Treatment_Start_DateTime    DATETIME2       NULL,
    Discharge_DateTime          DATETIME2       NULL,
    Admission_Type              VARCHAR(20)     NULL,   -- Emergency, Urgent, Elective, Transfer
    Severity_Level              TINYINT         NULL,   -- 1 (low) – 5 (high)
    Diagnosis_Category          VARCHAR(10)     NULL,   -- DX01 .. DXnn
    Length_of_Stay_Hours        DECIMAL(10,2)   NULL,
    Wait_Time_Minutes           DECIMAL(10,2)   NULL,
    Treatment_Delay_Minutes     DECIMAL(10,2)   NULL,
    ICU_Required_Flag           BIT             NULL,
    Outcome                     VARCHAR(20)     NULL,   -- Discharged, Admitted, Transferred, Deceased
    Mortality_Flag              BIT             NULL,
    Readmission_30_Days_Flag    BIT             NULL,
    Insurance_Type              VARCHAR(30)     NULL,
    Treatment_Cost              DECIMAL(12,2)   NULL,
    Revenue_Amount              DECIMAL(12,2)   NULL,
    Satisfaction_Score          DECIMAL(5,2)    NULL,
    Complaint_Flag              BIT             NULL,
    Ambulance_Arrival_Flag      BIT             NULL,
    Month                       TINYINT         NULL,
    Hospital_Name               VARCHAR(100)    NULL,
    Latitude                    DECIMAL(9,6)    NULL,
    Longitude                   DECIMAL(9,6)    NULL
);
GO

-- Update path to match the CSV location on the SQL Server host.
BULK INSERT dbo.Patient_Visits
FROM 'C:\Users\ALYAA\Desktop\Emergency Operations & Patient Flow Analytics.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '65001',
    TABLOCK
);
GO

SELECT COUNT(*) AS Total_Rows_Loaded FROM dbo.Patient_Visits;
GO


/* ============================================================================
   SECTION 2 — DATA QUALITY CHECK
   Quantify missing values in key fields before running any analysis.
   High missingness = impute or exclude from that model.
   ============================================================================ */

SELECT
    COUNT(*)                                                            AS Total_Visits,
    SUM(CASE WHEN Triage_DateTime           IS NULL THEN 1 ELSE 0 END) AS Missing_Triage_Time,
    SUM(CASE WHEN Treatment_Start_DateTime  IS NULL THEN 1 ELSE 0 END) AS Missing_Treatment_Start,
    SUM(CASE WHEN Discharge_DateTime        IS NULL THEN 1 ELSE 0 END) AS Missing_Discharge_Time,
    SUM(CASE WHEN Severity_Level            IS NULL THEN 1 ELSE 0 END) AS Missing_Severity,
    SUM(CASE WHEN Satisfaction_Score        IS NULL THEN 1 ELSE 0 END) AS Missing_Satisfaction,
    SUM(CASE WHEN Length_of_Stay_Hours      IS NULL THEN 1 ELSE 0 END) AS Missing_LOS,
    SUM(CASE WHEN Treatment_Cost            IS NULL THEN 1 ELSE 0 END) AS Missing_Cost,
    SUM(CASE WHEN Mortality_Flag            IS NULL THEN 1 ELSE 0 END) AS Missing_Mortality_Flag,
    SUM(CASE WHEN Readmission_30_Days_Flag  IS NULL THEN 1 ELSE 0 END) AS Missing_Readmission_Flag
FROM dbo.Patient_Visits;
GO


/* ============================================================================
   PART A — OPERATIONAL ANALYSIS
   ============================================================================ */


/* ============================================================================
   SECTION 3 — NETWORK-WIDE OPERATIONAL SNAPSHOT
   The opening question: what does the network look like at the highest level?
   Volume, severity mix, outcomes, and key flow metrics in one row.
   ============================================================================ */

SELECT
    COUNT(*)                                                            AS Total_Visits,
    COUNT(DISTINCT Patient_ID)                                          AS Unique_Patients,
    COUNT(DISTINCT Hospital_Name)                                       AS Hospitals,
    COUNT(DISTINCT Doctor_ID)                                           AS Doctors,
    COUNT(DISTINCT Department_ID)                                       AS Departments,

    -- Severity mix
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    SUM(CASE WHEN Severity_Level >= 4 THEN 1 ELSE 0 END)               AS High_Severity_Count,
    ROUND(100.0 * SUM(CASE WHEN Severity_Level >= 4 THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                                AS High_Severity_Pct,

    -- Flow metrics
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Minutes,
    ROUND(AVG(Treatment_Delay_Minutes), 1)                              AS Avg_Treatment_Delay_Minutes,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,

    -- Outcome summary
    SUM(CAST(ICU_Required_Flag AS INT))                                 AS ICU_Cases,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    SUM(CAST(Mortality_Flag AS INT))                                    AS Deaths,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    SUM(CAST(Readmission_30_Days_Flag AS INT))                         AS Readmissions_30d,
    ROUND(100.0 * SUM(CAST(Readmission_30_Days_Flag AS INT))
          / COUNT(*), 2)                                                AS Readmission_Rate_Pct,
    SUM(CAST(Ambulance_Arrival_Flag AS INT))                           AS Ambulance_Arrivals
FROM dbo.Patient_Visits;
GO


/* ============================================================================
   SECTION 4 — HOSPITAL PERFORMANCE COMPARISON
   Identifies the strongest and weakest sites across the key operational
   dimensions: volume, severity, wait times, LOS, and outcomes.
   ============================================================================ */

SELECT
    Hospital_Name,
    COUNT(*)                                                            AS Total_Visits,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(AVG(Treatment_Delay_Minutes), 1)                              AS Avg_Treatment_Delay_Min,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    SUM(CAST(ICU_Required_Flag AS INT))                                 AS ICU_Cases,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Readmission_30_Days_Flag AS INT))
          / COUNT(*), 2)                                                AS Readmission_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction,
    ROUND(100.0 * SUM(CAST(Complaint_Flag AS INT)) / COUNT(*), 1)      AS Complaint_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Hospital_Name
ORDER BY Mortality_Rate_Pct DESC;
GO


/* ============================================================================
   SECTION 5 — DEPARTMENT PERFORMANCE
   Shows which departments handle the highest acuity, longest stays, and
   worst outcomes — useful for resource and staffing decisions.
   ============================================================================ */

SELECT
    Department_ID,
    COUNT(*)                                                            AS Total_Visits,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Readmission_30_Days_Flag AS INT))
          / COUNT(*), 2)                                                AS Readmission_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction
FROM dbo.Patient_Visits
GROUP BY Department_ID
ORDER BY Avg_Severity DESC;
GO


/* ============================================================================
   SECTION 6 — ADMISSION TYPE BREAKDOWN
   Compares Emergency / Urgent / Elective / Transfer across severity, flow
   speed, and outcomes to identify which admission routes drive the most risk.
   ============================================================================ */

SELECT
    Admission_Type,
    COUNT(*)                                                            AS Total_Visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1)                  AS Pct_of_Total,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(AVG(Treatment_Delay_Minutes), 1)                              AS Avg_Treatment_Delay_Min,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Ambulance_Arrival_Flag AS INT))
          / COUNT(*), 1)                                                AS Ambulance_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Admission_Type
ORDER BY Mortality_Rate_Pct DESC;
GO


/* ============================================================================
   SECTION 7 — PATIENT FLOW BOTTLENECK ANALYSIS
   Breaks wait time and treatment delay into percentile bands to reveal
   where the real bottlenecks sit — average alone hides the tail risk.
   ============================================================================ */
WITH Calculated_Percentiles AS (
    SELECT 
        Wait_Time_Minutes,
        Treatment_Delay_Minutes,
        -- Calculate wait time percentiles across all rows
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Wait_Time_Minutes) OVER() AS Wait_P50_Raw,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY Wait_Time_Minutes) OVER() AS Wait_P90_Raw,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Wait_Time_Minutes) OVER() AS Wait_P95_Raw,
        -- Calculate treatment delay percentiles across all rows
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Treatment_Delay_Minutes) OVER() AS Delay_P50_Raw,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY Treatment_Delay_Minutes) OVER() AS Delay_P90_Raw,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Treatment_Delay_Minutes) OVER() AS Delay_P95_Raw
    FROM dbo.Patient_Visits
    WHERE Wait_Time_Minutes IS NOT NULL
)
SELECT
    -- Wait time distribution summary
    ROUND(MIN(Wait_Time_Minutes), 1) AS Wait_Min,
    ROUND(AVG(Wait_Time_Minutes), 1) AS Wait_Avg,
    ROUND(MAX(Wait_Time_Minutes), 1) AS Wait_Max,
    ROUND(MAX(Wait_P50_Raw), 1) AS Wait_P50,
    ROUND(MAX(Wait_P90_Raw), 1) AS Wait_P90,
    ROUND(MAX(Wait_P95_Raw), 1) AS Wait_P95,

    -- Treatment delay distribution summary
    ROUND(MIN(Treatment_Delay_Minutes), 1) AS Delay_Min,
    ROUND(AVG(Treatment_Delay_Minutes), 1) AS Delay_Avg,
    ROUND(MAX(Treatment_Delay_Minutes), 1) AS Delay_Max,
    ROUND(MAX(Delay_P50_Raw), 1) AS Delay_P50,
    ROUND(MAX(Delay_P90_Raw), 1) AS Delay_P90,
    ROUND(MAX(Delay_P95_Raw), 1) AS Delay_P95
FROM Calculated_Percentiles;

-- Wait time band × outcome: quantifies the human cost of long waits.
SELECT
    CASE
        WHEN Wait_Time_Minutes < 15  THEN 'A: < 15 min'
        WHEN Wait_Time_Minutes < 30  THEN 'B: 15–30 min'
        WHEN Wait_Time_Minutes < 60  THEN 'C: 30–60 min'
        WHEN Wait_Time_Minutes < 120 THEN 'D: 1–2 hrs'
        ELSE                              'E: > 2 hrs'
    END                                                             AS Wait_Band,
    COUNT(*)                                                        AS Visits,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                   AS Avg_Severity,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)  AS Mortality_Rate_Pct,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1) AS ICU_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                               AS Avg_Satisfaction
FROM dbo.Patient_Visits
GROUP BY
    CASE
        WHEN Wait_Time_Minutes < 15  THEN 'A: < 15 min'
        WHEN Wait_Time_Minutes < 30  THEN 'B: 15–30 min'
        WHEN Wait_Time_Minutes < 60  THEN 'C: 30–60 min'
        WHEN Wait_Time_Minutes < 120 THEN 'D: 1–2 hrs'
        ELSE                              'E: > 2 hrs'
    END
ORDER BY Wait_Band;
GO


/* ============================================================================
   SECTION 8 — DIAGNOSIS CATEGORY ANALYSIS
   Ranks diagnoses by volume, severity, LOS, and mortality to identify the
   highest-burden conditions across the network.
   ============================================================================ */

SELECT
    Diagnosis_Category,
    COUNT(*)                                                            AS Total_Visits,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Readmission_30_Days_Flag AS INT))
          / COUNT(*), 2)                                                AS Readmission_Rate_Pct,
    ROUND(AVG(Treatment_Cost), 0)                                       AS Avg_Treatment_Cost
FROM dbo.Patient_Visits
GROUP BY Diagnosis_Category
ORDER BY Mortality_Rate_Pct DESC;
GO


/* ============================================================================
   SECTION 9 — ICU UTILISATION ANALYSIS
   Maps ICU demand by hospital, admission type, and severity — essential for
   capacity planning and flagging sites that may be under-resourced for
   critical care.
   ============================================================================ */

-- ICU demand by hospital
SELECT
    Hospital_Name,
    COUNT(*)                                                            AS Total_Visits,
    SUM(CAST(ICU_Required_Flag AS INT))                                 AS ICU_Cases,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(AVG(CASE WHEN ICU_Required_Flag = 1
                   THEN Length_of_Stay_Hours END), 1)                  AS Avg_ICU_LOS_Hours,
    ROUND(100.0 * SUM(CASE WHEN ICU_Required_Flag = 1
                            AND Mortality_Flag = 1 THEN 1 ELSE 0 END)
          / NULLIF(SUM(CAST(ICU_Required_Flag AS INT)), 0), 2)         AS ICU_Mortality_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Hospital_Name
ORDER BY ICU_Rate_Pct DESC;
GO

-- ICU rate by severity level — confirms severity is a reliable ICU predictor.
SELECT
    Severity_Level,
    COUNT(*)                                                            AS Visits,
    SUM(CAST(ICU_Required_Flag AS INT))                                 AS ICU_Cases,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Severity_Level
ORDER BY Severity_Level;
GO


/* ============================================================================
   SECTION 10 — OUTCOME ANALYSIS
   Full outcome breakdown (Discharged / Admitted / Transferred / Deceased)
   by hospital and by admission type to surface the worst-performing routes.
   ============================================================================ */

-- Outcome mix by hospital
SELECT
    Hospital_Name,
    COUNT(*)                                                            AS Total_Visits,
    SUM(CASE WHEN Outcome = 'Discharged'  THEN 1 ELSE 0 END)           AS Discharged,
    SUM(CASE WHEN Outcome = 'Admitted'    THEN 1 ELSE 0 END)           AS Admitted,
    SUM(CASE WHEN Outcome = 'Transferred' THEN 1 ELSE 0 END)           AS Transferred,
    SUM(CASE WHEN Outcome = 'Deceased'    THEN 1 ELSE 0 END)           AS Deceased,
    ROUND(100.0 * SUM(CASE WHEN Outcome = 'Deceased' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                                AS Mortality_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Hospital_Name
ORDER BY Mortality_Rate_Pct DESC;
GO

-- Outcome by admission type
SELECT
    Admission_Type,
    Outcome,
    COUNT(*)                                                            AS Visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER
          (PARTITION BY Admission_Type), 1)                            AS Pct_Within_Type
FROM dbo.Patient_Visits
GROUP BY Admission_Type, Outcome
ORDER BY Admission_Type, Visits DESC;
GO


/* ============================================================================
   SECTION 11 — MONTHLY VOLUME & TREND ANALYSIS
   Tracks visit volume, severity mix, and wait times month by month to
   identify seasonality, demand spikes, or deteriorating performance.
   ============================================================================ */

SELECT
    Month,
    COUNT(*)                                                            AS Total_Visits,
    COUNT(DISTINCT Hospital_Name)                                       AS Active_Hospitals,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    SUM(CAST(ICU_Required_Flag AS INT))                                 AS ICU_Cases,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction,
    -- Month-over-month visit change
    COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY Month)                     AS MoM_Visit_Change
FROM dbo.Patient_Visits
GROUP BY Month
ORDER BY Month;
GO


/* ============================================================================
   SECTION 12 — DOCTOR PERFORMANCE ANALYSIS
   Ranks doctors by patient volume, average outcomes, and efficiency.
   Outliers (very high mortality or very long LOS) surface for clinical review.
   ============================================================================ */

SELECT
    Doctor_ID,
    COUNT(*)                                                            AS Total_Patients,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Patient_Severity,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction,
    ROUND(100.0 * SUM(CAST(Complaint_Flag AS INT)) / COUNT(*), 1)      AS Complaint_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Doctor_ID
HAVING COUNT(*) >= 20                                   -- exclude doctors with very few cases
ORDER BY Mortality_Rate_Pct DESC;
GO


/* ============================================================================
   SECTION 13 — INSURANCE TYPE & COST ANALYSIS
   Maps cost, revenue, and margin by insurance type to understand payer mix
   and cross-subsidisation across patient groups.
   ============================================================================ */

SELECT
    Insurance_Type,
    COUNT(*)                                                            AS Total_Visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1)                  AS Pct_of_Total,
    ROUND(AVG(Treatment_Cost), 0)                                       AS Avg_Treatment_Cost,
    ROUND(AVG(Revenue_Amount), 0)                                       AS Avg_Revenue,
    ROUND(AVG(Revenue_Amount) - AVG(Treatment_Cost), 0)                AS Avg_Margin,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction
FROM dbo.Patient_Visits
GROUP BY Insurance_Type
ORDER BY Avg_Margin DESC;
GO


/* ============================================================================
   SECTION 14 — PATIENT SATISFACTION & COMPLAINT DEEP DIVE
   Identifies which operational factors drive dissatisfaction and complaints
   so they can be prioritised for service improvement.
   ============================================================================ */

-- Satisfaction and complaint rate by hospital
SELECT
    Hospital_Name,
    COUNT(*)                                                            AS Visits,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction,
    ROUND(MIN(Satisfaction_Score), 2)                                   AS Min_Satisfaction,
    SUM(CAST(Complaint_Flag AS INT))                                    AS Total_Complaints,
    ROUND(100.0 * SUM(CAST(Complaint_Flag AS INT)) / COUNT(*), 1)      AS Complaint_Rate_Pct
FROM dbo.Patient_Visits
WHERE Satisfaction_Score IS NOT NULL
GROUP BY Hospital_Name
ORDER BY Avg_Satisfaction ASC;
GO

-- Satisfaction by severity and admission type — shows whether clinical
-- complexity alone explains low scores or whether service is the issue.
SELECT
    Severity_Level,
    Admission_Type,
    COUNT(*)                                                            AS Visits,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction,
    ROUND(100.0 * SUM(CAST(Complaint_Flag AS INT)) / COUNT(*), 1)      AS Complaint_Rate_Pct
FROM dbo.Patient_Visits
WHERE Satisfaction_Score IS NOT NULL
GROUP BY Severity_Level, Admission_Type
ORDER BY Avg_Satisfaction ASC;
GO


/* ============================================================================
   SECTION 15 — 30-DAY READMISSION DEEP DIVE
   Quantifies which hospitals, diagnoses, and discharge conditions produce
   the highest readmission rates — key for post-discharge care programmes.
   ============================================================================ */

-- Readmission rate by hospital
SELECT
    Hospital_Name,
    COUNT(*)                                                            AS Discharged_Visits,
    SUM(CAST(Readmission_30_Days_Flag AS INT))                         AS Readmissions,
    ROUND(100.0 * SUM(CAST(Readmission_30_Days_Flag AS INT))
          / COUNT(*), 2)                                                AS Readmission_Rate_Pct
FROM dbo.Patient_Visits
WHERE Outcome = 'Discharged'
GROUP BY Hospital_Name
ORDER BY Readmission_Rate_Pct DESC;
GO

-- Readmission rate by diagnosis and LOS band
-- Short stays + specific diagnoses = classic readmission signal.
SELECT
    Diagnosis_Category,
    CASE
        WHEN Length_of_Stay_Hours < 24  THEN 'Under 1 day'
        WHEN Length_of_Stay_Hours < 72  THEN '1–3 days'
        WHEN Length_of_Stay_Hours < 168 THEN '3–7 days'
        ELSE                                 'Over 7 days'
    END                                                                 AS LOS_Band,
    COUNT(*)                                                            AS Visits,
    SUM(CAST(Readmission_30_Days_Flag AS INT))                         AS Readmissions,
    ROUND(100.0 * SUM(CAST(Readmission_30_Days_Flag AS INT))
          / COUNT(*), 2)                                                AS Readmission_Rate_Pct
FROM dbo.Patient_Visits
WHERE Outcome = 'Discharged'
GROUP BY
    Diagnosis_Category,
    CASE
        WHEN Length_of_Stay_Hours < 24  THEN 'Under 1 day'
        WHEN Length_of_Stay_Hours < 72  THEN '1–3 days'
        WHEN Length_of_Stay_Hours < 168 THEN '3–7 days'
        ELSE                                 'Over 7 days'
    END
HAVING COUNT(*) >= 10
ORDER BY Readmission_Rate_Pct DESC;
GO


/* ============================================================================
   SECTION 16 — AMBULANCE & EMERGENCY RESPONSE
   Compares ambulance vs walk-in patients on acuity, outcomes, and speed
   of care to evaluate whether the pre-hospital pathway is working.
   ============================================================================ */

SELECT
    Ambulance_Arrival_Flag,
    COUNT(*)                                                            AS Visits,
    ROUND(AVG(CAST(Severity_Level AS FLOAT)), 2)                       AS Avg_Severity,
    ROUND(AVG(Wait_Time_Minutes), 1)                                    AS Avg_Wait_Min,
    ROUND(AVG(Treatment_Delay_Minutes), 1)                              AS Avg_Treatment_Delay_Min,
    ROUND(AVG(Length_of_Stay_Hours), 1)                                 AS Avg_LOS_Hours,
    ROUND(100.0 * SUM(CAST(ICU_Required_Flag AS INT)) / COUNT(*), 1)   AS ICU_Rate_Pct,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct,
    ROUND(AVG(Satisfaction_Score), 2)                                   AS Avg_Satisfaction
FROM dbo.Patient_Visits
GROUP BY Ambulance_Arrival_Flag;
GO


/* ============================================================================
   PART B — PREDICTIVE ANALYSIS
   ============================================================================ */


/* ============================================================================
   SECTION 17 — MORTALITY RISK SCORING MODEL
   Additive risk score from historically significant predictors, validated
   against actual mortality rate per tier. Computable in real time at triage.
   ============================================================================ */

-- Step 1: Historical mortality rate per predictor — confirms weight direction.
SELECT
    Severity_Level,
    Admission_Type,
    ICU_Required_Flag,
    COUNT(*)                                                            AS Visit_Count,
    SUM(CAST(Mortality_Flag AS INT))                                    AS Deaths,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)      AS Mortality_Rate_Pct
FROM dbo.Patient_Visits
GROUP BY Severity_Level, Admission_Type, ICU_Required_Flag
ORDER BY Mortality_Rate_Pct DESC;
GO

-- Step 2: Score every visit, bucket into tiers, validate against actual deaths.
WITH Risk_Scored AS (
    SELECT
        Visit_ID, Severity_Level, Admission_Type,
        ICU_Required_Flag, Mortality_Flag,
        (ISNULL(Severity_Level, 0) * 1.2)
        + (CASE WHEN ICU_Required_Flag = 1                          THEN 3.0 ELSE 0 END)
        + (CASE WHEN Admission_Type IN ('Emergency','Transfer')     THEN 2.0 ELSE 0 END)
        + (CASE WHEN Treatment_Delay_Minutes > 60                   THEN 1.5 ELSE 0 END)
        + (CASE WHEN Ambulance_Arrival_Flag = 1                     THEN 0.5 ELSE 0 END)
        AS Risk_Score
    FROM dbo.Patient_Visits
)
SELECT
    CASE
        WHEN Risk_Score >= 8 THEN '1 - Critical'
        WHEN Risk_Score >= 5 THEN '2 - High'
        WHEN Risk_Score >= 3 THEN '3 - Moderate'
        ELSE                      '4 - Low'
    END                                                             AS Risk_Tier,
    COUNT(*)                                                        AS Visit_Count,
    SUM(CAST(Mortality_Flag AS INT))                                AS Actual_Deaths,
    ROUND(100.0 * SUM(CAST(Mortality_Flag AS INT)) / COUNT(*), 2)  AS Actual_Mortality_Rate_Pct
FROM Risk_Scored
GROUP BY
    CASE
        WHEN Risk_Score >= 8 THEN '1 - Critical'
        WHEN Risk_Score >= 5 THEN '2 - High'
        WHEN Risk_Score >= 3 THEN '3 - Moderate'
        ELSE                      '4 - Low'
    END
ORDER BY Risk_Tier;
GO


/* ============================================================================
   SECTION 18 — 30-DAY READMISSION RISK PREDICTION
   Readmission probability lookup by diagnosis × LOS band.
   Used at point of discharge to flag high-risk patients for follow-up.
   ============================================================================ */

SELECT
    Diagnosis_Category,
    CASE
        WHEN Length_of_Stay_Hours < 24  THEN 'Under 1 day'
        WHEN Length_of_Stay_Hours < 72  THEN '1–3 days'
        WHEN Length_of_Stay_Hours < 168 THEN '3–7 days'
        ELSE                                 'Over 7 days'
    END                                                             AS LOS_Band,
    COUNT(*)                                                        AS Visit_Count,
    SUM(CAST(Readmission_30_Days_Flag AS INT))                      AS Readmissions,
    CAST(SUM(CAST(Readmission_30_Days_Flag AS INT)) AS DECIMAL(10,4))
        / NULLIF(COUNT(*), 0)                                       AS Predicted_Readmission_Probability
FROM dbo.Patient_Visits
WHERE Outcome = 'Discharged'
GROUP BY
    Diagnosis_Category,
    CASE
        WHEN Length_of_Stay_Hours < 24  THEN 'Under 1 day'
        WHEN Length_of_Stay_Hours < 72  THEN '1–3 days'
        WHEN Length_of_Stay_Hours < 168 THEN '3–7 days'
        ELSE                                 'Over 7 days'
    END
HAVING COUNT(*) >= 10
ORDER BY Predicted_Readmission_Probability DESC;
GO


/* ============================================================================
   SECTION 19 — LENGTH OF STAY FORECASTING
   Mean ± 1 STDEV per diagnosis × severity = point forecast + confidence range.
   Feeds bed-planning and discharge scheduling models.
   ============================================================================ */

SELECT
    Diagnosis_Category,
    Severity_Level,
    COUNT(*)                                                        AS Sample_Size,
    ROUND(AVG(Length_of_Stay_Hours), 1)                             AS Predicted_LOS_Hours,
    ROUND(STDEV(Length_of_Stay_Hours), 1)                           AS LOS_StdDev,
    ROUND(AVG(Length_of_Stay_Hours) - STDEV(Length_of_Stay_Hours), 1) AS LOS_Lower_Bound,
    ROUND(AVG(Length_of_Stay_Hours) + STDEV(Length_of_Stay_Hours), 1) AS LOS_Upper_Bound
FROM dbo.Patient_Visits
WHERE Length_of_Stay_Hours IS NOT NULL
GROUP BY Diagnosis_Category, Severity_Level
HAVING COUNT(*) >= 10
ORDER BY Predicted_LOS_Hours DESC;
GO


/* ============================================================================
   SECTION 20 — ICU REQUIREMENT PREDICTION
   Probability of ICU need by severity × admission type × ambulance arrival.
   Apply at triage to pre-allocate ICU capacity before a bed is requested.
   ============================================================================ */

SELECT
    Severity_Level,
    Admission_Type,
    Ambulance_Arrival_Flag,
    COUNT(*)                                                        AS Visit_Count,
    SUM(CAST(ICU_Required_Flag AS INT))                             AS ICU_Cases,
    CAST(SUM(CAST(ICU_Required_Flag AS INT)) AS DECIMAL(10,4))
        / NULLIF(COUNT(*), 0)                                       AS Predicted_ICU_Probability
FROM dbo.Patient_Visits
GROUP BY Severity_Level, Admission_Type, Ambulance_Arrival_Flag
HAVING COUNT(*) >= 10
ORDER BY Predicted_ICU_Probability DESC;
GO


/* ============================================================================
   SECTION 21 — PATIENT VOLUME FORECASTING (TIME SERIES)
   Next-month visit forecast per hospital using linear trend extrapolation
   (latest month volume + average monthly change via LAG).
   ============================================================================ */

DROP TABLE IF EXISTS #Monthly_Volume;
DROP TABLE IF EXISTS #Volume_With_Trend;

SELECT
    Hospital_Name,
    Month,
    COUNT(*) AS Visit_Count
INTO #Monthly_Volume
FROM dbo.Patient_Visits
GROUP BY Hospital_Name, Month;

SELECT
    Hospital_Name,
    Month,
    Visit_Count,
    LAG(Visit_Count) OVER (PARTITION BY Hospital_Name ORDER BY Month) AS Prior_Month_Count,
    Visit_Count
        - LAG(Visit_Count) OVER (PARTITION BY Hospital_Name ORDER BY Month) AS MoM_Change
INTO #Volume_With_Trend
FROM #Monthly_Volume;

SELECT
    v.Hospital_Name,
    MAX(v.Month)                AS Latest_Month,
    AVG(v.MoM_Change)          AS Avg_Monthly_Trend,
    (SELECT TOP 1 v2.Visit_Count
     FROM #Volume_With_Trend v2
     WHERE v2.Hospital_Name = v.Hospital_Name
     ORDER BY v2.Month DESC)
     + AVG(v.MoM_Change)       AS Forecasted_Next_Month_Visits
FROM #Volume_With_Trend v
GROUP BY v.Hospital_Name
ORDER BY Forecasted_Next_Month_Visits DESC;
GO


/* ============================================================================
   SECTION 22 — PATIENT SATISFACTION PREDICTION
   Expected satisfaction score and complaint probability by wait-time band.
   Flags visits likely to generate complaints before the patient leaves.
   ============================================================================ */

SELECT
    CASE
        WHEN Wait_Time_Minutes < 15  THEN 'A: < 15 min'
        WHEN Wait_Time_Minutes < 30  THEN 'B: 15–30 min'
        WHEN Wait_Time_Minutes < 60  THEN 'C: 30–60 min'
        ELSE                              'D: > 60 min'
    END                                                             AS Wait_Band,
    COUNT(*)                                                        AS Visit_Count,
    ROUND(AVG(Satisfaction_Score), 2)                               AS Predicted_Satisfaction_Score,
    CAST(SUM(CAST(Complaint_Flag AS INT)) AS DECIMAL(10,4))
        / NULLIF(COUNT(*), 0)                                       AS Predicted_Complaint_Probability
FROM dbo.Patient_Visits
WHERE Satisfaction_Score IS NOT NULL
GROUP BY
    CASE
        WHEN Wait_Time_Minutes < 15  THEN 'A: < 15 min'
        WHEN Wait_Time_Minutes < 30  THEN 'B: 15–30 min'
        WHEN Wait_Time_Minutes < 60  THEN 'C: 30–60 min'
        ELSE                              'D: > 60 min'
    END
ORDER BY Wait_Band;
GO


/* ============================================================================
   SECTION 23 — COMPOSITE PATIENT RISK PREDICTIONS (ALL MODELS IN ONE VIEW)
   Merges mortality score, readmission probability, and LOS prediction into
   one row per visit — the output a clinician or bed manager acts on.
   Temp tables pre-compute lookup values for readmission base rates and LOS.
   ============================================================================ */

IF OBJECT_ID('tempdb..#DiagReadmission') IS NOT NULL DROP TABLE #DiagReadmission;
IF OBJECT_ID('tempdb..#LOSLookup')       IS NOT NULL DROP TABLE #LOSLookup;

-- Diagnosis-level readmission base rates (prior probability).
SELECT
    Diagnosis_Category,
    CAST(SUM(CAST(Readmission_30_Days_Flag AS INT)) AS DECIMAL(10,4))
        / NULLIF(COUNT(*), 0)   AS Readmission_Base_Rate
INTO #DiagReadmission
FROM dbo.Patient_Visits
WHERE Outcome = 'Discharged'
GROUP BY Diagnosis_Category;
GO

-- Diagnosis × severity mean LOS and variability.
SELECT
    Diagnosis_Category,
    Severity_Level,
    AVG(Length_of_Stay_Hours)   AS Predicted_LOS_Hours,
    STDEV(Length_of_Stay_Hours) AS LOS_StdDev
INTO #LOSLookup
FROM dbo.Patient_Visits
WHERE Length_of_Stay_Hours IS NOT NULL
GROUP BY Diagnosis_Category, Severity_Level
HAVING COUNT(*) >= 5;
GO

-- Main composite prediction — one row per visit.
WITH Scored AS (
    SELECT
        pv.Visit_ID,
        pv.Patient_ID,
        pv.Hospital_Name,
        pv.Department_ID,
        pv.Admission_Type,
        pv.Severity_Level,
        pv.Diagnosis_Category,
        pv.Insurance_Type,
        pv.Length_of_Stay_Hours     AS LOS_Actual,
        pv.Mortality_Flag           AS Mortality_Actual,
        pv.Readmission_30_Days_Flag AS Readmission_Actual,

        -- MODEL 1 — Mortality score normalised to 0–1 (max raw score = 13).
        CAST((
            (ISNULL(pv.Severity_Level, 0) * 1.2)
          + (CASE WHEN pv.ICU_Required_Flag = 1                        THEN 3.0 ELSE 0 END)
          + (CASE WHEN pv.Admission_Type IN ('Emergency','Transfer')   THEN 2.0 ELSE 0 END)
          + (CASE WHEN pv.Treatment_Delay_Minutes > 60                 THEN 1.5 ELSE 0 END)
          + (CASE WHEN pv.Ambulance_Arrival_Flag = 1                   THEN 0.5 ELSE 0 END)
        ) AS DECIMAL(5,2))                              AS Mortality_Risk_Score,

        CAST((
            (ISNULL(pv.Severity_Level, 0) * 1.2)
          + (CASE WHEN pv.ICU_Required_Flag = 1                        THEN 3.0 ELSE 0 END)
          + (CASE WHEN pv.Admission_Type IN ('Emergency','Transfer')   THEN 2.0 ELSE 0 END)
          + (CASE WHEN pv.Treatment_Delay_Minutes > 60                 THEN 1.5 ELSE 0 END)
          + (CASE WHEN pv.Ambulance_Arrival_Flag = 1                   THEN 0.5 ELSE 0 END)
        ) / 13.0 AS DECIMAL(5,4))                       AS Mortality_Predicted_Prob,

        CASE
            WHEN ((ISNULL(pv.Severity_Level,0)*1.2)
                + (CASE WHEN pv.ICU_Required_Flag=1 THEN 3 ELSE 0 END)
                + (CASE WHEN pv.Admission_Type IN ('Emergency','Transfer') THEN 2 ELSE 0 END)
                + (CASE WHEN pv.Treatment_Delay_Minutes>60 THEN 1.5 ELSE 0 END)
                + (CASE WHEN pv.Ambulance_Arrival_Flag=1 THEN 0.5 ELSE 0 END)) >= 8 THEN 'CRITICAL'
            WHEN ((ISNULL(pv.Severity_Level,0)*1.2)
                + (CASE WHEN pv.ICU_Required_Flag=1 THEN 3 ELSE 0 END)
                + (CASE WHEN pv.Admission_Type IN ('Emergency','Transfer') THEN 2 ELSE 0 END)
                + (CASE WHEN pv.Treatment_Delay_Minutes>60 THEN 1.5 ELSE 0 END)
                + (CASE WHEN pv.Ambulance_Arrival_Flag=1 THEN 0.5 ELSE 0 END)) >= 5 THEN 'HIGH'
            WHEN ((ISNULL(pv.Severity_Level,0)*1.2)
                + (CASE WHEN pv.ICU_Required_Flag=1 THEN 3 ELSE 0 END)
                + (CASE WHEN pv.Admission_Type IN ('Emergency','Transfer') THEN 2 ELSE 0 END)
                + (CASE WHEN pv.Treatment_Delay_Minutes>60 THEN 1.5 ELSE 0 END)
                + (CASE WHEN pv.Ambulance_Arrival_Flag=1 THEN 0.5 ELSE 0 END)) >= 3 THEN 'MODERATE'
            ELSE 'LOW'
        END                                             AS Mortality_Risk_Tier,

        -- MODEL 2 — Readmission: diagnosis base rate × LOS band × severity.
        CAST(
            ISNULL(dr.Readmission_Base_Rate, 0.10)
            * (CASE
                WHEN pv.Length_of_Stay_Hours < 24  THEN 1.40
                WHEN pv.Length_of_Stay_Hours < 72  THEN 1.10
                WHEN pv.Length_of_Stay_Hours < 168 THEN 0.90
                ELSE 0.75
               END)
            * (CASE WHEN pv.Severity_Level >= 4 THEN 1.25 ELSE 1.0 END)
        AS DECIMAL(5,4))                                AS Readmission_Predicted_Prob,

        -- MODEL 3 — LOS: mean for this diagnosis/severity pair.
        ISNULL(los.Predicted_LOS_Hours,
               (SELECT AVG(Length_of_Stay_Hours) FROM dbo.Patient_Visits)) AS LOS_Predicted_Hours,
        ISNULL(los.LOS_StdDev, 0)                       AS LOS_Confidence_StdDev

    FROM dbo.Patient_Visits pv
    LEFT JOIN #DiagReadmission dr  ON pv.Diagnosis_Category = dr.Diagnosis_Category
    LEFT JOIN #LOSLookup       los ON pv.Diagnosis_Category = los.Diagnosis_Category
                                  AND pv.Severity_Level     = los.Severity_Level
)
SELECT
    Visit_ID, Patient_ID, Hospital_Name, Department_ID,
    Admission_Type, Severity_Level, Diagnosis_Category, Insurance_Type,

    -- Mortality outputs
    Mortality_Risk_Score,
    Mortality_Predicted_Prob,
    Mortality_Risk_Tier,
    Mortality_Actual,
    CASE WHEN Mortality_Predicted_Prob >= 0.40 THEN 1 ELSE 0 END            AS Mortality_Predicted_Flag,

    -- Readmission outputs
    CAST(CASE WHEN Readmission_Predicted_Prob > 1 THEN 1.0
              ELSE Readmission_Predicted_Prob END AS DECIMAL(5,4))           AS Readmission_Predicted_Prob,
    CASE WHEN Readmission_Predicted_Prob >= 0.20 THEN 1 ELSE 0 END          AS Readmission_Predicted_Flag,
    Readmission_Actual,

    -- LOS outputs
    CAST(LOS_Predicted_Hours                         AS DECIMAL(8,1))        AS LOS_Predicted_Hours,
    CAST(LOS_Predicted_Hours - LOS_Confidence_StdDev AS DECIMAL(8,1))        AS LOS_Lower_Bound,
    CAST(LOS_Predicted_Hours + LOS_Confidence_StdDev AS DECIMAL(8,1))        AS LOS_Upper_Bound,
    CAST(LOS_Actual                                  AS DECIMAL(8,1))        AS LOS_Actual

FROM Scored
ORDER BY Mortality_Predicted_Prob DESC;
GO


/* ============================================================================
   SECTION 24 — MODEL ACCURACY VALIDATION (CONFUSION MATRIX)
   Measures mortality model performance: Accuracy, Precision, Recall.
   Re-run after any weight adjustment to check if it improved.
   ============================================================================ */

WITH Scored AS (
    SELECT
        CAST(Mortality_Flag AS INT) AS Mortality_Actual,
        CASE WHEN (
            (ISNULL(Severity_Level,0) * 1.2)
          + (CASE WHEN ICU_Required_Flag = 1                          THEN 3.0 ELSE 0 END)
          + (CASE WHEN Admission_Type IN ('Emergency','Transfer')     THEN 2.0 ELSE 0 END)
          + (CASE WHEN Treatment_Delay_Minutes > 60                   THEN 1.5 ELSE 0 END)
          + (CASE WHEN Ambulance_Arrival_Flag = 1                     THEN 0.5 ELSE 0 END)
        ) / 13.0 >= 0.40 THEN 1 ELSE 0 END AS Mortality_Predicted
    FROM dbo.Patient_Visits
    WHERE Mortality_Flag IS NOT NULL
)
SELECT
    SUM(CASE WHEN Mortality_Actual=1 AND Mortality_Predicted=1 THEN 1 ELSE 0 END) AS True_Positive,
    SUM(CASE WHEN Mortality_Actual=0 AND Mortality_Predicted=0 THEN 1 ELSE 0 END) AS True_Negative,
    SUM(CASE WHEN Mortality_Actual=0 AND Mortality_Predicted=1 THEN 1 ELSE 0 END) AS False_Positive,
    SUM(CASE WHEN Mortality_Actual=1 AND Mortality_Predicted=0 THEN 1 ELSE 0 END) AS False_Negative,
    CAST(SUM(CASE WHEN Mortality_Actual = Mortality_Predicted THEN 1 ELSE 0 END) AS DECIMAL(10,4))
        / COUNT(*)                                                                  AS Accuracy,
    CAST(SUM(CASE WHEN Mortality_Actual=1 AND Mortality_Predicted=1 THEN 1 ELSE 0 END) AS DECIMAL(10,4))
        / NULLIF(SUM(CASE WHEN Mortality_Predicted=1 THEN 1 ELSE 0 END),0)         AS Precision,
    CAST(SUM(CASE WHEN Mortality_Actual=1 AND Mortality_Predicted=1 THEN 1 ELSE 0 END) AS DECIMAL(10,4))
        / NULLIF(SUM(CASE WHEN Mortality_Actual=1 THEN 1 ELSE 0 END),0)            AS Recall,
    COUNT(*) AS Total_Visits
FROM Scored;
GO


/* ============================================================================
   SECTION 25 — TOP HIGH-RISK PATIENTS (ACTIONABLE TRIAGE LIST)
   Combines both risk models into a prioritised list for clinical staff.
   CRITICAL / HIGH / READMISSION WATCH patients surface at the top.
   ============================================================================ */

WITH RiskScored AS (
    SELECT
        pv.Visit_ID, pv.Patient_ID, pv.Hospital_Name,
        pv.Admission_Type, pv.Severity_Level,
        pv.Diagnosis_Category, pv.Outcome,
        pv.Length_of_Stay_Hours,

        -- Mortality probability (0–1)
        CAST((
            (ISNULL(pv.Severity_Level,0) * 1.2)
          + (CASE WHEN pv.ICU_Required_Flag=1 THEN 3 ELSE 0 END)
          + (CASE WHEN pv.Admission_Type IN ('Emergency','Transfer') THEN 2 ELSE 0 END)
          + (CASE WHEN pv.Treatment_Delay_Minutes>60 THEN 1.5 ELSE 0 END)
          + (CASE WHEN pv.Ambulance_Arrival_Flag=1 THEN 0.5 ELSE 0 END)
        ) / 13.0 AS DECIMAL(5,4))       AS Mortality_Prob,

        -- Readmission probability using hard-coded diagnosis base rates.
        CAST(
            (CASE pv.Diagnosis_Category
                WHEN 'DX01' THEN 0.18 WHEN 'DX02' THEN 0.15 WHEN 'DX03' THEN 0.12
                WHEN 'DX04' THEN 0.22 WHEN 'DX05' THEN 0.10 WHEN 'DX06' THEN 0.14
                WHEN 'DX07' THEN 0.19 WHEN 'DX08' THEN 0.16 WHEN 'DX09' THEN 0.21
                WHEN 'DX10' THEN 0.13 WHEN 'DX11' THEN 0.17 WHEN 'DX12' THEN 0.20
                ELSE 0.15
             END)
            * (CASE WHEN pv.Length_of_Stay_Hours < 24 THEN 1.4 ELSE 1.0 END)
            * (CASE WHEN pv.Severity_Level >= 4 THEN 1.25 ELSE 1.0 END)
        AS DECIMAL(5,4))                AS Readmission_Prob

    FROM dbo.Patient_Visits pv
)
SELECT TOP 100
    Visit_ID, Patient_ID, Hospital_Name,
    Admission_Type, Severity_Level, Diagnosis_Category, Outcome,
    CAST(Mortality_Prob   * 100 AS DECIMAL(5,1)) AS Mortality_Risk_Pct,
    CAST(Readmission_Prob * 100 AS DECIMAL(5,1)) AS Readmission_Risk_Pct,
    CAST(Length_of_Stay_Hours   AS DECIMAL(8,1)) AS LOS_Hours,
    CASE
        WHEN Mortality_Prob   >= 0.55 THEN 'CRITICAL'
        WHEN Mortality_Prob   >= 0.40 THEN 'HIGH'
        WHEN Readmission_Prob >= 0.25 THEN 'READMISSION WATCH'
        ELSE                               'STANDARD'
    END AS Overall_Risk_Flag
FROM RiskScored
WHERE Mortality_Prob >= 0.40 OR Readmission_Prob >= 0.25
ORDER BY Mortality_Prob DESC, Readmission_Prob DESC;
GO


