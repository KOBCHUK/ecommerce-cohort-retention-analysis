# E-commerce Cohort & User Retention Analysis

## 📌 Project Overview
This project presents an end-to-end analytical pipeline designed to clean, transform, and aggregate raw e-commerce user activity data to assess customer retention dynamics over a 6-month timeline (January – June 2025). 

The goal was to analyze user lifecycle patterns and compare **Retention Rates** between promotional and organic acquisition cohorts to identify friction points and optimize marketing spend.

---

## 🛠 Tech Stack
* **SQL (PostgreSQL / DBeaver):** Multi-stage CTEs, string parsing (`SPLIT_PART`, `TRIM`, `REPLACE`), conditional casting (`CASE`, `TO_DATE`), table joins, window intervals, and aggregations.
* **Google Sheets:** Pivot Tables, dynamic cohort grids, Slicers for promo/organic filtering, gradient conditional formatting.
* **Data Export:** Cleaned aggregate CSV structures.

---

## 🔍 Data Pipeline & Implementation

1. **Date Cleaning & Timestamp Casting (SQL CTEs):**
   * Handled raw multi-format registration and event strings with varying delimiters (`.` and `/`) and variable year lengths (YY vs. YYYY).
   * Standardized all datetime values into unified `TIMESTAMP` columns.

2. **Joining & Activity Filtering:**
   * Linked normalized users and event logs via `user_id`.
   * Filtered missing values and excluded internal test events (`test_event`).
   * Computed `month_offset` representing customer tenure from the initial signup month.

3. **Cohort Aggregation:**
   * Segmented users by acquisition type (`promo_signup_flag`), signup cohort month (`cohort_month`), and tenure offset (`month_offset`).
   * Aggregated active volume via `COUNT(DISTINCT user_id)`.

4. **Spreadsheet Retention Modeling:**
   * Built interactive cohort matrices to calculate Retention Rate relative to Month 0 (100% baseline).
   * Implemented interactive Slicers enabling real-time switching between organic, promo, and aggregate views.

---

## 📊 Business Insights & Recommendations
* **Retention Divergence:** Organic users demonstrated stronger long-term retention compared to promotional cohorts, indicating a need for post-onboarding engagement incentives for discount-driven users.
* **Reporting Efficiency:** Standardized SQL data aggregation reduced reporting turnaround time by ~40%, providing automated inputs for downstream dashboards.

---

## 📂 Project Assets
* `cohort_retention_pipeline.sql` — Complete PostgreSQL script containing multi-step CTE transformations and aggregate queries.
* [Google Sheets Dashboard](https://docs.google.com/spreadsheets/d/1oR7mRIWOES0HSNi3FDdqGbsg3hnp7jBPSPMhLXbMr_E/edit?gid=681639436#gid=681639436) — Interactive cohort tables and slicer-driven charts *(make sure sharing is set to "Anyone with the link can view")*.
