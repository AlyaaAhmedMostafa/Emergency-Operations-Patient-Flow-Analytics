# 🏥 # 🏥 Healthcare Network Intelligence: A Unified SQL Predictive Framework & Power BI Command Centre

> *"The difference between data and intelligence is the story it tells."*

This repository brings together two complementary healthcare analytics case studies — a **Power BI operational command centre** built across 11 real NHS hospital trusts (*Code Blue*), and a **deep SQL predictive-analytics framework** demonstrated on a 5-facility hospital network. Together they show the full pipeline: from raw triage logs and rule-based risk scoring in SQL Server, to an executive-ready three-page dashboard NHS boards can act on in under 60 seconds.

---

## 📋 Table of Contents

- [Part I — Code Blue: NHS Emergency Operations & Patient Flow Dashboard](#part-i--code-blue-nhs-emergency-operations--patient-flow-dashboard)
  - [Project Overview](#project-overview)
  - [Dashboard Pages](#dashboard-pages)
  - [System-Wide Key Findings](#system-wide-key-findings)
  - [Strengths](#strengths--what-the-nhs-system-is-doing-right)
  - [Weaknesses](#weaknesses--where-the-system-is-breaking-down)
  - [Strategic Recommendations](#strategic-recommendations)
- [Part II — SQL Predictive Analytics Framework (5-Hospital Case Study)](#part-ii--sql-predictive-analytics-framework-5-hospital-case-study)
  - [Executive Summary](#executive-summary--core-insights)
  - [Data Architecture & Pipeline](#integrated-data-architecture--pipeline)
  - [Front-End vs. Back-End Flow](#macro-operational-pipeline-front-end-vs-back-end-flow)
  - [Volume Forecasting Matrix](#volume-forecasting--operational-scalability-matrix)
  - [Text-Mining & Clinical Priority Alignment](#text-mining-framework--clinical-priority-alignment)
  - [Algorithmic Mortality Risk Score](#algorithmic-mortality-risk-score-synthesis)
  - [Predictive Model Evaluation](#predictive-analytics-classification-model-evaluation)
  - [Longitudinal Cohort Analytics](#longitudinal-patient-analytics--cohort-tracking)
  - [Final Recommendations](#final-executive-recommendations)
- [Combined Technical Stack](#-combined-technical-stack)
- [The Unified Narrative](#-the-unified-narrative)

---

## Part I — Code Blue: NHS Emergency Operations & Patient Flow Dashboard

**FP20 Analytics Challenge 38 — NHS System Intelligence Dashboard**

### Project Overview

This Power BI dashboard delivers a three-page analytical deep-dive into NHS emergency operations, patient flow, staffing pressure, and financial sustainability across **11 hospitals** — from Large Urban Trauma Centres to Underfunded Public facilities.

The central question driving the analysis:

> *When a healthcare system looks stable on paper, where exactly is it quietly breaking down — and what should leadership do about it?*

The answer unfolds across three pages, each building on the last.

### Dashboard Pages

| Page | Focus | Audience |
|---|---|---|
| **1 — Executive Command Centre** | System health at a glance: high-level KPIs, hospital performance matrix, archetype breakdown, real-time critical alert panel | C-suite & NHS board decision-makers |
| **2 — Operational Pressure Map** | Burnout vs. overtime by hospital, visit volume by severity, chronic conditions vs. ICU demand, outcome distribution | Operations managers & clinical directors |
| **3 — Strategic Outcomes & Action Plan** | Quality-vs-financial health matrix, satisfaction trends, prioritised action cards | Strategy leads & NHS commissioners |

### System-Wide Key Findings

| Metric | Value |
|---|---|
| Avg Wait Time | 61.37 minutes |
| Readmission Rate (30d) | 17.04% |
| Avg Patient Satisfaction | 62.50 |
| Mortality Rate | 3.32% |
| Bed Occupancy | 54.0% |
| Total Revenue | £10.07bn |
| Avg Profit Margin | 17.44% |

These numbers suggest a system that is functioning — but facility-level data tells a very different story.

### Strengths — What the NHS System Is Doing Right

**🟢 High-Volume Efficiency Leaders — Alder Hey & UCL**
Despite handling the highest patient volumes in the dataset (930+ visits), both maintain satisfaction scores above 63.0 under only moderate staffing stress — proof that high throughput and clinical excellence are not mutually exclusive. Their triage protocols and staffing ratios should be documented and shared network-wide.

**🟢 Leeds — The Financial & Clinical Sweet Spot**
Leeds combines the highest profit margin in the dataset (~19.3%) with a below-average readmission rate (~16.3%) — evidence of disciplined discharge planning and effective post-acute coordination. Its care-coordination model is a candidate template for trust-wide improvement.

**🟢 Bristol — Clinical Excellence Under Financial Pressure**
Bristol posts the system's lowest readmission rate (~15.7%); its challenge is purely financial, not clinical. Its protocols deserve investment, not cuts — the funding gap is a commissioner-level issue.

**🟢 Uniform Patient Distribution**
Each of the 11 hospitals accounts for 8.76%–9.38% of total visits — an even spread that makes cross-facility benchmarking statistically valid without volume-bias adjustment.

**🟢 4-Hour Compliance**
System-wide 4-hour compliance sits at 98.8%, exceeding the NHS 95% standard — a strong result even during winter pressure.

### Weaknesses — Where the System Is Breaking Down

**🔴 Sandwell General — A Compounding Crisis**
The single most urgent intervention priority: satisfaction at 28.9 (a 56% collapse vs. system average), mortality at 6% (double the network average), and a burnout index of 0.96 — near the scale maximum. This is a systemic cascade: chronic understaffing → extended waits → eroded quality → rising readmissions → dangerous mortality, each problem amplifying the next.

**🔴 Seasonal Winter Surge — A Predictable Crisis Treated as a Surprise**
January is the operational peak network-wide: Resus cases hit 52 (yearly high), Urgent cases hit 363 (~35% above the June trough), overtime and burnout (0.65+) spike, and satisfaction collapses in lockstep. The same pattern repeats across 2024 into 2025 — entirely predictable, yet handled reactively.

**🔴 Cornwall & Norfolk — Financial Sustainability Risks**
Both sit in the vulnerable quadrant: low margins (~15.5%–16.0%) paired with high readmission rates (~17.0%–18.0%). Norfolk's elevated ICU demand reflects a patient mix weighted toward medium-to-high acuity chronic conditions.

**🔴 King's, Alder Hey & Norfolk — Quality Risk Despite Financial Health**
Financially strong (17.5%–18.5% margins) but carrying the highest readmission rates in the system (King's peaks near 18.3%) — financial performance is masking a discharge/community-care gap.

**🔴 January 2025 Satisfaction Collapse — A System-Wide Signal**
Satisfaction fell to a historic ~64.0 low while complaints surged past 8.5% — the leading indicator of the same winter failure pattern recurring on schedule into late 2025.

### Strategic Recommendations

**Immediate (0–3 months)**
1. **Emergency Intervention at Sandwell General** — cross-functional turnaround team, bank/agency staffing reinforcement, 6-month mortality review, enhanced NHS oversight. At 0.96 burnout, the workforce cannot self-recover.
2. **Pre-Winter Staffing Contracts** — lock in contingency staffing by September, given the reliable November–January surge pattern.

**Medium-Term (3–12 months)**
3. **Replicate the Spire & Nuffield Model** — burnout ~0.38, readmission 3–6%, satisfaction 84–88; benchmark their workforce and discharge-planning models for NHS Foundation Trust adaptation.
4. **Bristol Financial Recovery Programme** — a commissioner-level review of payer mix and funding allocation, not a reduction in clinical resources.
5. **Post-Acute Care Investment** for King's, Norfolk, and Alder Hey — community care coordination and discharge follow-up to cut readmissions.

**Long-Term (12+ months)**
6. **Risk-Stratified Chronic Condition Management** — ICU strain is driven by acuity mix, not volume; target High/Medium-risk chronic patients before they deteriorate to Critical (Bristol, Harrogate, Leeds).
7. **Seasonal Demand-Based Elective Scheduling** — shift electives to the May–July trough to build buffer capacity ahead of winter surges.

---

## Part II — SQL Predictive Analytics Framework (5-Hospital Case Study)

*A methodology deep-dive: how rule-based SQL scoring, text mining, and cohort analytics turn raw transactional logs into predictive intelligence — demonstrated across City Medical Center, Hope Veterans Hospital, St. Jude Hospital, General Hospital, and Grace Community.*

### Executive Summary & Core Insights

Connecting raw patient timelines, unstructured triage notes, rule-based classification, and longitudinal cohort analysis exposes one central reality: **hospital volume drives exponential operational bottlenecks, which scale directly into clinical risk and patient dissatisfaction.**

```
                 [Patient Flow Bottleneck Found]
                                ↓
        Front-End Triage Rooming  ──>  Fast (11.0 min median)
        Back-End Internal Delay   ──>  Slow (29.0 min median)
                                ↓
    [High Volume at City Medical] ──> Exponential SLA Breaches (24.1% / 19.8%)
                                ↓
    [Clinical Compounding]        ──> Delays >60 min inflate Mortality Risk (+1.5)
                                ↓
    [Sentiment Mismatch]          ──> Speed alone ≠ satisfaction (19.5% precision gap)
```

**Core deductions:**
- **The Throughput Mismatch** — front-end triage is fast (11.0 min median); the real breakdown is inside the exam room, where patients wait a further 29.0 minutes for treatment to begin.
- **The Volumetric Scaling Wall** — volume doesn't degrade efficiency linearly. Doubling from St. Jude (~1,000 encounters) to City Medical (~2,155) *triples* the SLA breach rate, from 8.5% to 24.1%.
- **Operational Penalties on Mortality Risk** — patients with identical initial severity score meaningfully higher on the composite mortality index purely because of a >60-minute internal delay.
- **The Illusion of Speed in Satisfaction** — SLA timing predicts sentiment well (85.4% recall) but a 19.5% precision gap shows meeting speed targets doesn't guarantee satisfaction; bedside manner and care coordination matter too.

### Integrated Data Architecture & Pipeline

```
[Raw Patient Transaction Logs]
       ↓
[Feature Engineering Layer] ──> String Normalization (LOWER / LIKE) & Index Mapping (CHARINDEX)
       ↓
[Analytical Engine Layer]   ──> Window Functions (PERCENTILE_CONT) via CTE Core Tiering
       ↓
[Predictive Scoring Core]   ──> Rule-Based Risk Weighting Matrix & SLA Binary Flags
       ↓
[Longitudinal Analytics]    ──> Multi-Month Cohort Self-Joins & Matrix Pivots
       ↓
[Macro Executive Reporting] ──> Network Compliance SLA Auditing Dashboard
```

1. **Descriptive & Windowing Phase** — statistical ranges computed inside a CTE using `OVER()` window functions, comparing each row to network percentiles without premature aggregation.
2. **NLP & Feature Engineering Phase** — raw triage narratives parsed via `LOWER` normalization and `CHARINDEX` boundary tracking to extract clinical flags (`Is_Cardiac`, `Is_Respiratory`, `Is_Abdominal`).
3. **Algorithmic Predictive Scoring Phase** — multi-conditional `CASE` logic weights biological metrics (acuity, ICU status) against operational markers to produce real-time risk and satisfaction scores.
4. **Longitudinal Analytics Phase** — date-offset self-joins build multi-month retention matrices, separating transient ER visits from chronic-care cohorts.
5. **Executive Synthesis Phase** — rolls patient-level metrics into a macro compliance grid driving staffing and capacity decisions.

### Macro Operational Pipeline: Front-End vs. Back-End Flow

**Front-End — Door-to-Room (`Wait_Time_Minutes`)**
Minimum 0.0 min (immediate rooming for critical trauma), median (P50) 11.0 min, mean 14.8 min. P90 = 32.0 min, P95 = 41.0 min, max = 177.0 min — the top 5% face real backlogs, but the baseline system is fast.

**Back-End — Room-to-Treatment (`Treatment_Delay_Minutes`)**
Median jumps to 29.0 min (mean 31.4 min) — patients wait nearly 3x longer *inside* the room than in reception. P95 = 61.0 min, max = 155.0 min.

> **Operational Diagnosis:** The bottleneck is not room availability or intake capacity — it is internal throughput: the time for physicians, labs, or imaging to reach an already-roomed patient.

### Volume Forecasting & Operational Scalability Matrix

| Hospital | 3-Month MoM Trend | Avg Monthly Drift | Next-Month Forecast | Network Rank | Wait SLA Breach | Treatment SLA Breach |
|---|---|---|---|---|---|---|
| **City Medical Center** | 748 → 717 → 690 | -29.0 | **661.0** | 1 (Flagship) | **24.1%** | **19.8%** |
| **Hope Veterans Hospital** | 469 → 487 → 532 | +31.5 | **563.5** | 2 (Surge Point) | **14.3%** | **11.2%** |
| **St. Jude Hospital** | 333 → 369 → 341 | +4.0 | **345.0** | 3 (Stable) | 8.5% | 7.1% |
| **General Hospital** | 198 → 172 → 212 | +7.0 | **219.0** | 4 (Stable) | 4.2% | 3.8% |
| **Grace Community** | 106 → 111 → 104 | -1.0 | **103.0** | 5 (Micro) | 2.1% | 1.5% |

**Facility insights:**
- **City Medical Center (The Strained Giant)** — drifting down -29.0 visits/month toward a projected 661, yet still breaching 30-min rooming 24.1% of the time and the 60-min care target 19.8% of the time. Volume is easing; strain isn't.
- **Hope Veterans Hospital (The Escalation Danger Zone)** — growing at +31.5 visits/month toward a projected 563.5. Breach rates already in double digits; on track to mirror City Medical's profile within ~60 days without intervention.
- **St. Jude & General Hospital (The Optimized Sweet Spot)** — stable, single-digit breach rates (3.8%–8.5%); staffing matches local demand.
- **Grace Community (The Surplus Micro-Site)** — near-zero systemic friction, breach rates below 2.1%.

### Text-Mining Framework & Clinical Priority Alignment

| Flag | Captures |
|---|---|
| `Is_Cardiac = 1` | chest pain, palpitations, cold sweats, shortness of breath |
| `Is_Respiratory = 1` | cough, wheezing, congestion, shortness of breath |
| `Is_Abdominal = 1` | abdominal pain, nausea, localized cramping, vomiting |

```
[Arriving Patient Notes parsed via Text Mining]
       │
       ├─► Is_Cardiac = 1     ──► Triage Priority: High   ──► Median Wait: 4.0 min
       └─► Is_Abdominal = 1   ──► Triage Priority: Medium ──► Median Wait: 16.5 min
```

Cardiac-flagged patients wait a median of just 4.0 minutes network-wide vs. 16.5 minutes for abdominal-flagged patients — confirmation that front-desk intake correctly fast-tracks life-threatening cardiovascular presentations.

### Algorithmic Mortality Risk Score Synthesis

$$\text{Mortality Risk Score} = (\text{Severity} \times 1.2) + (\text{ICU Flag} \times 3.0) + (\text{Admission Source Flag} \times 2.0) + (\text{Operational Delay Penalty} \times 1.5)$$

Score range: **0.0 – 11.70**

**High-risk cohort audit:**
- **Patients 1421 & 2289 (Score 10.70)** — Severity Level 4 (4.80 base), unplanned Emergency entry (+2.00), ICU placement (+3.00), plus a +1.50 operational delay penalty for exceeding 60 minutes in-room before treatment.
- **Patient 3110 (Score 8.00)** — identical biological baseline (Level 4, ICU, Emergency), but treatment began under 60 minutes, avoiding the 1.50-point penalty entirely.

> **Clinical Conclusion:** Operational delay is not a neutral inconvenience — it measurably raises risk for the most vulnerable patients. This supports real-time EHR alerts when an Acuity Level 4 patient approaches 45 minutes without treatment.

### Predictive Analytics Classification Model Evaluation

Rule-based satisfaction prediction across 7,000 cases, using time-based SLA parameters:

| | Predicted Satisfied | Predicted Unsatisfied |
|---|---|---|
| **Actually Satisfied** | TP = 2,541 | FN = 433 |
| **Actually Unsatisfied** | FP = 614 | TN = 3,412 |

- **Accuracy: 75.1%** — 3 of 4 encounters correctly classified.
- **Precision: 80.5%** — a 19.5% false-positive rate: timeline metrics look fine, but the patient was still unsatisfied.
- **Recall: 85.4%** — only 14.6% of genuinely satisfied patients are missed.

**The gap:** speed is a *necessary but not sufficient* condition for satisfaction. The 614 false positives — patients roomed under 30 min and treated under 60 min who still left dissatisfied — point to variables invisible to timeline data: bedside manner, discharge clarity, care coordination.

### Longitudinal Patient Analytics & Cohort Tracking

```
[Baseline Cohort (Month 0)]  ──► 100% (Initial Visit Entry Point)
            ↓
[Drop-off Phase (Month 1)]   ──► Drops to 12%–18% (successful resolution of acute cases)
            ↓
[Chronic Floor (Months 2-3)] ──► Plateaus at 8%–14% (long-term chronic management)
```

- **Month 0 (100.0%)** — initial cohort baseline for a given entry month.
- **Acute Resolution Drop-off (12.0%–18.0%)** — a sharp Month-1 drop is a *quality signal*: ~85% of patients had their acute issue fully resolved on the first visit, no bounce-back needed.
- **Chronic Care Plateau (8.0%–14.0%)** — the residual floor represents patients managing long-term conditions (chronic heart failure, advanced respiratory disease, recurring metabolic issues) who rely on the facility for continuous episodic care.

**Cross-facility comparison:**
- **Hope Veterans Hospital (High-Retention)** — stickier long-term return rate, consistent with an older/veteran population using the site as a medical home.
- **City Medical Center (High-Throughput)** — sharp Month-0 drop-off typical of a fast urban trauma centre serving transient, one-off crisis populations.

### Final Executive Recommendations

1. **Shift Investment to Back-End Throughput at City Medical** — exam-room delays (36.2 min avg) run roughly double front-end waits (18.4 min avg); fund internal workflow acceleration (lab runners, streamlined physician review) over waiting-room expansion to bring down the 19.8% treatment breach rate.
2. **Reallocate Staffing to the Hope Veterans Surge** — shift nursing/admin support from stable or declining sites (City Medical, Grace Community) to Hope Veterans before its +31.5/month growth pushes it into double-digit breach territory permanently.
3. **Deploy a Real-Time High-Risk EHR Alert** — wire the `Is_Cardiac` text-mining flag plus high initial severity into triage tracking; trigger an alert at 20 minutes of internal delay to protect against the 1.50-point mortality risk penalty.

---

## 🔧 Combined Technical Stack

| Layer | Tool | Usage |
|---|---|---|
| Data modelling | Microsoft SQL Server (T-SQL) | CTEs, window functions (`PERCENTILE_CONT`, `OVER()`), rule-based `CASE` scoring, self-join cohort matrices |
| Text intelligence | T-SQL string functions | `LOWER`, `CHARINDEX`, `LIKE` pattern flags for unstructured triage notes |
| Predictive scoring | Rule-based weighting matrices | Mortality risk score, SLA-driven satisfaction classifier (confusion matrix validated) |
| Dashboarding | Power BI Desktop | 3-page executive dashboard, DAX measures, data modelling |
| Semantic layer | DAX | Readmission rate, profit margin, burnout index, severity buckets |
| Transformation | Power Query | Column creation, severity short-labels, data cleansing |
| Data model | Star schema | `Fact_Patient_Visits`, `Fact_Staffing`, `Fact_Financials` + dimension tables |

---

## 🧭 The Unified Narrative

Both case studies converge on the same finding from two different angles: **operational bottlenecks are not neutral — they compound directly into clinical risk, financial strain, and patient sentiment, and they are largely predictable rather than random.**

- The **SQL layer** (Part II) proves this at the transactional level: internal treatment delay, not front-door intake, is the real bottleneck, and it measurably raises a patient's mortality risk score and satisfaction odds.
- The **Power BI layer** (Part I) proves it at the network level: Sandwell General's collapse and the recurring January winter surge are cascading, foreseeable failures — not one-off anomalies.

Neither network is failing outright — both are **fragile in predictable ways**. Their strongest performers (Leeds, Alder Hey, UCL, St. Jude, Grace Community) prove that high-quality, financially sustainable, well-paced care is achievable at scale. Their weakest points are not mysteries; they are the visible endpoint of understaffing, delayed internal throughput, and a seasonal/volume pattern the data has already flagged well in advance.

**The opportunity is the same in both studies:** replicate what already works, intervene early where the cascade has started, and build the forecasting and risk-scoring capacity to treat "predictable" surges as *planned* events rather than recurring surprises.
