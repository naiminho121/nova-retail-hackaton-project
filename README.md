# Nova Retail — Modern Data Stack

## Project Overview

Nova Retail is a global technology and electronics retailer with fragmented data across Sales, Marketing Reviews and Finance.

The objective of this project is to build an end-to-end modern data platform that transforms heterogeneous raw data into a trusted, business-ready analytical model and an executive BI dashboard.

The solution follows a Medallion-style architecture:

**Local Files → Dataiku → Snowflake Bronze → dbt Silver → dbt Gold → Power BI**

---

## Architecture

```text
                         LOCAL DATA SOURCES
                                │
                ┌───────────────┼───────────────┐
                │               │               │
             Sales CSV      Reviews JSON    Finance Excel
                │               │               │
                └───────────────┼───────────────┘
                                ▼
                             DATAIKU
                         Ingestion & Profiling
                                │
                                ▼
                       SNOWFLAKE — BRONZE
                                │
                                ▼
                         DBT — SILVER
                    Cleaning & Standardization
                                │
                                ▼
                          DBT — GOLD
                       Dimensional Model
                                │
                 ┌──────────────┼──────────────┐
                 │              │              │
            DIMENSIONS       FACTS          FACTS
                 │              │              │
                 └──────────────┼──────────────┘
                                ▼
                            POWER BI
                       Executive Dashboard
```

---

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Ingestion & profiling | Dataiku | Local data ingestion, exploration and initial data quality analysis |
| Data warehouse | Snowflake | Centralized cloud storage and compute |
| Transformation | dbt | Data cleaning, transformation, modelling, testing and documentation |
| BI | Power BI | Executive dashboard and business analysis |
| Version control | GitHub | Source control and project collaboration |

---

## Source Data

### 1. Sales Transactions

`raw_sales_transactions.csv`

The sales dataset contains transaction-level information including:

- Order
- Transaction date
- Customer information
- Product
- Category
- Price
- Quantity
- Discount

The source is highly denormalized and contains several data quality issues such as mixed date formats, embedded customer information, mixed currency formats and inconsistent discount representations.

### 2. Web Reviews

`web_reviews.json`

The reviews dataset contains:

- Review
- Product
- Customer
- Location
- Timestamp
- Rating
- Review text

The original JSON structure contains nested customer and location attributes and timestamps using different precisions.

### 3. Finance Targets

`finance_targets_2023.xlsx`

The finance dataset contains monthly revenue targets by:

- Region
- Product Category
- Month

The original data is stored in a wide format and is transformed into a monthly analytical structure.

---

## Data Architecture

### Bronze

The Bronze layer contains the raw ingested source data.

Tables:

- `NOVARETAIL_RAW_SALES_TRANSACTIONS_COPY`
- `NOVARETAIL_WEB_REVIEWS_COPY`
- `NOVARETAIL_FINANCE_TARGETS_2023_COPY`

The objective is to preserve source information before applying analytical transformations.

### Silver

The Silver layer contains cleaned and standardized datasets.

Models:

- `STG_SALES_TRANSACTIONS`
- `STG_WEB_REVIEWS`
- `STG_FINANCE_TARGETS`

Main transformations include:

- Date standardization
- Customer information parsing
- Price and currency cleaning
- Discount standardization
- Return identification
- Review timestamp normalization
- Rating validation
- Finance target unpivoting

### Gold

The Gold layer contains the business-ready dimensional model used by Power BI.

#### Dimensions

- `DIM_DATE`
- `DIM_CUSTOMER`
- `DIM_PRODUCT`

#### Facts

- `FCT_SALES`
- `FCT_TARGETS`

The Gold model is designed around clearly defined grains and relationships.

---

## Gold Model

### FCT_SALES

**Grain:** one row per sales order.

Key measures:

- Revenue
- Profit
- Quantity
- Discount

Profit is calculated using the 30% margin assumption specified in the project brief.

### FCT_TARGETS

**Grain:** one row per Region + Category + Month.

The table contains:

- Region
- Category
- Month
- Target Amount

A dedicated dbt test validates the uniqueness of this grain.

For the complete visual ERD, see:

`GOLD_ERD.md`

---

## Data Quality

Data quality issues are explicitly identified and documented rather than silently removing problematic records.

Examples include:

- Mixed date formats
- Missing dates
- Embedded customer attributes
- Mixed currencies
- Negative quantities
- Inconsistent discount formats
- Mixed timestamp precision
- Missing or invalid review ratings
- Wide-format finance targets
- Missing finance region values

Detailed treatment and assumptions are documented in:

`DATA_QUALITY.md`

---

## dbt Testing

The Gold layer is validated using dbt tests covering:

- Not-null constraints
- Uniqueness
- Dimension relationships
- Fact table grain
- Referential integrity

The project currently passes all configured dbt tests.

---

## Documentation

The repository contains:

- `GOLD_ERD.md` — Gold layer entity relationship diagram
- `DATA_QUALITY.md` — Data quality issues, treatments, assumptions and schema drift strategy
- `models/schema.yml` — dbt model and column documentation
- `models/sources.yml` — Bronze source definitions

---

## BI Dashboard

Power BI is connected exclusively to the Gold analytical model.

The executive dashboard is designed to provide:

### Sales Performance

- Total Revenue
- Total Profit
- Total Orders
- Average Order Value
- MTD vs Previous MTD
- YTD vs Previous YTD
- Daily / weekly sales trends
- Moving Average

### Target Performance

- Actual Revenue vs Target Revenue
- Monthly target performance
- Regional performance
- Distance from target

### Interactivity

- Reporting date selection
- Product Category filtering
- Region filtering
- Category → Product drill-down

---

## Key Design Decisions

### No artificial Region relationship

Sales transactions do not contain a region attribute. Therefore, no artificial relationship between sales and target regions has been created.

### Currency preservation

Sales contain multiple currencies. Since no FX source was provided, no currency conversion was performed. The original currency is preserved.

### Reviews remain in Silver

Reviews are cleaned and retained in Silver but are not included in Gold because review metrics are not required by the specified executive dashboard.

### Missing dates are retained

Sales records with missing or unresolved dates are retained with a `NULL` transaction date instead of being deleted.

---

## Project Structure

```text
nova-retail-hackaton-project/
│
├── models/
│   ├── core/
│   │   ├── dim_customer.sql
│   │   ├── dim_date.sql
│   │   ├── dim_product.sql
│   │   ├── fct_sales.sql
│   │   └── fct_targets.sql
│   │
│   ├── staging/
│   │   ├── stg_sales_transactions.sql
│   │   ├── stg_web_reviews.sql
│   │   └── stg_finance_targets.sql
│   │
│   ├── schema.yml
│   └── sources.yml
│
├── macros/
│   └── generate_schema_name.sql
│
├── tests/
│   └── fct_targets_unique_grain.sql
│
├── GOLD_ERD.md
├── DATA_QUALITY.md
├── README.md
└── dbt_project.yml
```

---

## End-to-End Flow

The complete pipeline is:

**Dataiku → Snowflake Bronze → dbt Silver → dbt Gold → Power BI**

This architecture separates raw ingestion, data transformation and business consumption while providing data quality testing, documentation and a clear analytical model.