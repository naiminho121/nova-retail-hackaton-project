# Nova Retail

End-to-end data analytics project for a global technology and electronics retailer.

The project transforms raw sales, customer reviews and financial target data into an analytics-ready data model for business intelligence reporting.

## Project Overview

Nova Retail integrates data from multiple sources and follows a modern analytics architecture:

```text
Local Files
    ↓
Dataiku
    ↓
Snowflake Bronze
    ↓
dbt Silver
    ↓
dbt Gold
    ↓
Power BI
```

The main objective is to build a reliable and scalable data pipeline that supports sales performance analysis, financial reporting and target tracking.

## Data Sources

The project uses three main business sources:

- `raw_sales_transactions.csv`
- `web_reviews.json`
- `finance_targets_2023.xlsx`

An additional ECB historical exchange-rate dataset is used to standardize USD and GBP sales into EUR.

### Sales Transactions

Contains order-level sales information including:

- Order ID
- Transaction date
- Customer information
- Product information
- Quantity
- Price
- Currency
- Discount

### Web Reviews

Contains customer review information including:

- Review ID
- Product reference
- Customer information
- Location
- Timestamp
- Rating
- Review text

### Finance Targets

Contains monthly financial targets by:

- Region
- Product category
- Month

The original dataset is provided in a wide monthly format and is transformed into a long analytical structure.

### ECB Exchange Rates

Historical ECB reference exchange rates are used for USD and GBP transactions.

The exchange-rate data allows sales originally recorded in different currencies to be standardized to EUR for global financial analysis.

## Architecture

### Bronze

The Bronze layer contains raw or minimally prepared source data loaded into Snowflake.

Main source tables:

- `NOVARETAIL_RAW_SALES_TRANSACTIONS_COPY`
- `NOVARETAIL_WEB_REVIEWS_COPY`
- `NOVARETAIL_FINANCE_TARGETS_2023_COPY`
- `NOVARETAIL_EUROFXREF_HIST_PREPARED_COPY`

### Silver

The Silver layer contains cleaned and standardized source-level models created with dbt.

Main transformations include:

- Date standardization
- Customer information splitting
- Price and currency normalization
- Discount standardization
- Return identification
- Review timestamp normalization
- Rating validation
- Finance target unpivoting
- FX data reshaping

Main staging models:

- `stg_sales_transactions`
- `stg_web_reviews`
- `stg_finance_targets`
- `stg_fx_ecb`

### Gold

The Gold layer contains analytics-ready dimensional and fact models.

#### Dimensions

- `dim_date`
- `dim_customer`
- `dim_product`

#### Facts

- `fct_sales`
- `fct_targets`

The model follows a simple star-schema approach designed for Power BI reporting.

## Gold Model

```text
                    DIM_DATE
                       │
              ┌────────┴────────┐
              │                 │
         FCT_SALES          FCT_TARGETS
          /     \
         /       \
DIM_CUSTOMER   DIM_PRODUCT
```

### FCT_SALES

The sales fact table has one row per order.

It contains:

- Transaction date
- Customer and product keys
- Quantity
- Price
- Original currency
- Discount
- Return indicator
- Revenue
- Profit
- FX rate information
- Revenue in EUR
- Profit in EUR

For USD and GBP transactions, the latest available ECB reference rate on or before the transaction date is used.

EUR transactions use an exchange rate of `1`.

The EUR-converted measures are:

- `revenue_eur`
- `profit_eur`

These measures are used for cross-currency financial analysis.

### FCT_TARGETS

The target fact table contains monthly financial targets.

Its grain is:

**Region + Category + Month**

The source does not explicitly specify the currency of the target amounts, so the target currency is treated as a project assumption rather than a confirmed source attribute.

## Currency Standardization

The project uses ECB reference exchange rates to standardize USD and GBP sales into EUR.

ECB rates represent units of the original currency per EUR.

Therefore:

```text
Revenue EUR = Revenue in Original Currency / ECB Rate
```

For example:

```text
USD Revenue / USD per EUR = EUR Revenue
```

When an applicable FX rate is unavailable, the EUR-converted value remains `NULL`.

No exchange rate is estimated or imputed.

## Data Quality

Data quality is addressed throughout the pipeline using both transformation rules and dbt tests.

Examples include:

- Standardizing multiple date formats
- Handling missing and invalid dates
- Splitting customer information
- Normalizing discounts
- Identifying returned orders
- Validating review ratings
- Converting timestamps
- Reshaping financial targets
- Validating FX data grain
- Validating EUR currency conversion

The project uses dbt generic tests such as:

- `not_null`
- `unique`
- `relationships`
- `accepted_values`

It also includes singular tests for project-specific business rules.

All current dbt models and tests pass successfully.

## Key Data Quality Findings

The source data contains several intentional quality challenges:

- 7 sales records have missing or invalid transaction dates.
- 3 sales records have an UNKNOWN currency.
- 1 sales transaction contains a negative quantity and is identified as a return.
- 12 reviews have missing or invalid ratings after validation.
- 4 finance target records have Region assigned as `NA` based on the source structure.
- 8 sales records do not have EUR-converted revenue because a valid conversion could not be performed.

These records are retained rather than artificially corrected or removed.

## Power BI

The Gold layer is consumed by Power BI for business intelligence reporting.

The dashboard focuses on:

### Sales Performance

- Total Revenue
- Total Profit
- Total Orders
- Average Order Value
- Monthly performance
- Daily and weekly sales trends
- Moving averages
- MTD performance
- YTD performance
- Previous-period comparisons
- Percentage variance

### Target Tracking

- Actual Revenue vs Target Revenue
- Monthly target performance
- Regional target analysis
- Distance from target

The Power BI model uses the Gold dimensions and fact tables rather than querying the raw source data directly.

## Important Modelling Decisions

### No Sales Region

The sales source does not contain regional information.

Therefore, no sales region has been inferred or artificially created.

Regional information is only available in the finance target dataset.

### No Direct Sales-to-Target Relationship

`FCT_SALES` and `FCT_TARGETS` are intentionally not directly related.

The two datasets have different available dimensions and grains:

- Sales → Order level
- Targets → Region + Category + Month

A future regional mapping would be required to perform regional actual-vs-target analysis at sales level.

### Product Category and Targets

Product category filters currently apply to sales through `DIM_PRODUCT`.

There is no shared category dimension connecting `DIM_PRODUCT` to `FCT_TARGETS`.

Therefore, category-based target comparisons require additional modelling if this functionality is expanded in the future.

### Reviews

Web reviews remain in the Silver layer because review metrics are outside the current Power BI reporting scope.

## Technology Stack

| Technology | Purpose |
|---|---|
| Dataiku | Data preparation and source ingestion |
| Snowflake | Cloud data warehouse |
| dbt | Data transformation, modelling, testing and documentation |
| Power BI | Business intelligence and visualization |
| GitHub | Version control and project documentation |
| ECB Reference Rates | Currency standardization |

## Project Structure

```text
nova-retail/
│
├── models/
│   ├── staging/
│   │   ├── stg_sales_transactions.sql
│   │   ├── stg_web_reviews.sql
│   │   ├── stg_finance_targets.sql
│   │   └── stg_fx_ecb.sql
│   │
│   ├── core/
│   │   ├── dim_date.sql
│   │   ├── dim_customer.sql
│   │   ├── dim_product.sql
│   │   ├── fct_sales.sql
│   │   └── fct_targets.sql
│   │
│   └── schema.yml
│
├── tests/
│   ├── fct_targets_unique_grain.sql
│   ├── fct_targets_positive_amount.sql
│   ├── stg_fx_ecb_unique_grain.sql
│   └── fct_sales_fx_conversion.sql
│
├── macros/
│   └── generate_schema_name.sql
│
├── README.md
├── DATA_QUALITY.md
└── GOLD_ERD.md
```

## Documentation

Additional documentation is available in:

- `GOLD_ERD.md` — Gold-layer data model and relationships
- `DATA_QUALITY.md` — Data quality rules, tests, assumptions and limitations

## Key Outcome

Nova Retail provides an end-to-end example of how raw multi-source data can be transformed into a governed analytical model using a modern data stack.

The final architecture combines:

**Data Preparation → Cloud Data Warehouse → dbt Transformation & Testing → Dimensional Modelling → Business Intelligence**

The resulting Gold layer provides a structured foundation for Power BI reporting while keeping data-quality issues, modelling assumptions and technical limitations transparent.