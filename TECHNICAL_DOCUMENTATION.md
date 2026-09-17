# Nova Retail — Technical Documentation

## End-to-End Data Analytics Project

Nova Retail is an end-to-end data analytics project developed for a global technology and electronics retailer.

The project integrates sales transactions, customer reviews and financial target data into a structured analytical platform.

The objective is to transform raw multi-source data into a reliable, tested and analytics-ready data model that supports business intelligence reporting and sales performance analysis.

---

# 1. Project Overview

The solution follows a modern data analytics architecture combining data preparation, cloud data warehousing, transformation, data quality validation and business intelligence.

The complete data flow is:

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

Each layer has a specific responsibility:

Layer	Technology	Purpose
Source	Local files	Original business data
Preparation	Dataiku	Source preparation and ingestion
Bronze	Snowflake	Raw or minimally prepared data
Silver	dbt	Cleaning and standardization
Gold	dbt	Dimensional modelling and business logic
BI	Power BI	Business analysis and visualization

The architecture separates data ingestion, transformation and reporting so that each stage can be validated independently.

2. Data Architecture
2.1 Data Sources

The project uses three main business datasets:

raw_sales_transactions.csv
web_reviews.json
finance_targets_2023.xlsx

An additional historical ECB exchange-rate dataset is used to standardize USD and GBP transactions into EUR.

The main business data covers the 2023 reporting period.

2.2 Data Preparation with Dataiku

Dataiku is used as the preparation and ingestion layer.

The source datasets are prepared before being loaded into Snowflake Bronze.

The preparation process addresses source-level issues such as:

File ingestion
Initial data inspection
Column selection
Data formatting
Source standardization
Exchange-rate preparation

The ECB historical reference dataset is filtered to the 2023 reporting period before being loaded into Snowflake.

Dataiku therefore acts as the controlled entry point between the original files and the cloud data warehouse.

2.3 Snowflake Bronze Layer

Snowflake provides the cloud data warehouse used by the project.

The Bronze layer stores the prepared source datasets with minimal transformation.

The main Bronze tables are:

NOVA_RETAIL.BRONZE.NOVARETAIL_RAW_SALES_TRANSACTIONS_COPY
NOVA_RETAIL.BRONZE.NOVARETAIL_WEB_REVIEWS_COPY
NOVA_RETAIL.BRONZE.NOVARETAIL_FINANCE_TARGETS_2023_COPY
NOVA_RETAIL.BRONZE.NOVARETAIL_EUROFXREF_HIST_PREPARED_COPY

The Bronze layer preserves the source-level information and provides the input for dbt staging models.

2.4 dbt Silver Layer

The Silver layer contains cleaned and standardized versions of the source data.

dbt models read the Bronze tables using dbt source() references.

The main staging models are:

stg_sales_transactions
stg_web_reviews
stg_finance_targets
stg_fx_ecb

Typical transformations include:

Date standardization
Customer information splitting
Price normalization
Currency identification
Discount standardization
Return identification
Review timestamp conversion
Rating validation
Finance target unpivoting
FX data reshaping

The staging layer is primarily responsible for making source data consistent and analysis-ready without introducing unnecessary business modelling.

2.5 dbt Gold Layer

The Gold layer contains the final analytical model used by Power BI.

The model follows a dimensional star-schema approach.

The Gold layer contains:

Dimensions
DIM_DATE
DIM_CUSTOMER
DIM_PRODUCT
Facts
FCT_SALES
FCT_TARGETS

The Gold layer introduces the business logic required for reporting, including:

Customer and product keys
Revenue calculations
Profit calculations
EUR currency conversion
Return identification
Target modelling
Relationships between facts and dimensions

Gold models are materialized as tables because they represent the final analytical layer consumed by Power BI.

3. End-to-End Data Flow

The complete pipeline can be summarized as follows:

┌───────────────────────────────┐
│        Local Data Sources     │
│                               │
│  Sales CSV                    │
│  Reviews JSON                 │
│  Finance Targets XLSX         │
│  ECB FX Reference Data        │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│            Dataiku            │
│                               │
│  Data preparation             │
│  Source inspection            │
│  Initial transformations      │
│  FX preparation               │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│       Snowflake BRONZE        │
│                               │
│  Raw / prepared source data   │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│          dbt SILVER           │
│                               │
│  Cleaning                     │
│  Standardization              │
│  Validation                   │
│  Source-level modelling       │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│           dbt GOLD            │
│                               │
│  Dimensions                   │
│  Facts                        │
│  Business logic               │
│  EUR conversion               │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│           Power BI            │
│                               │
│  Executive KPIs               │
│  Time intelligence            │
│  Target analysis              │
│  Interactive reporting        │
└───────────────────────────────┘

This separation provides a clear lineage from the original source data to the final business reporting layer.

4. Architecture Principles

The solution follows several principles throughout the project:

Separation of responsibilities

Each technology has a defined role:

Dataiku → preparation and ingestion
Snowflake → data storage
dbt → transformation, modelling, testing and documentation
Power BI → business intelligence
Source preservation

Source-level information is retained wherever possible.

Data-quality issues are documented rather than silently removed or replaced with unsupported assumptions.

Layered transformation

Transformations are progressively applied:

Raw data
   ↓
Cleaned data
   ↓
Business model
   ↓
Business reporting
Tested analytical model

The Gold layer is validated using dbt tests covering:

Uniqueness
Nullability
Referential integrity
Accepted values
Business rules
FX conversion consistency
Transparent assumptions

Known limitations and assumptions are documented explicitly, including:

Missing sales dates
Unknown currencies
Missing FX conversions
Missing target regions
Unspecified target currency
Absence of sales region information

This ensures that analytical results remain traceable to the available source data.


# 5. Data Sources

The Nova Retail pipeline integrates multiple datasets with different structures and business purposes.

## 5.1 Sales Transactions

Source:

`raw_sales_transactions.csv`

The sales dataset contains order-level transaction information.

Main attributes include:

- Order ID
- Transaction date
- Customer information
- Product ID
- Product category
- Quantity
- Price
- Discount

The source contains intentional data-quality issues such as mixed date formats, missing dates, mixed currency representations and inconsistent discount formats.

These issues are handled in the Silver layer.

---

## 5.2 Web Reviews

Source:

`web_reviews.json`

The reviews dataset contains customer feedback associated with products.

Main attributes include:

- Review ID
- Product reference
- Customer information
- Customer location
- Timestamp
- Rating
- Review text

The source contains timestamps using both 10-digit and 13-digit Unix formats.

Ratings are validated against the expected range of 1 to 5.

Reviews are cleaned in the Silver layer but are not included in the final Gold reporting model because review metrics are outside the current Power BI reporting scope.

---

## 5.3 Finance Targets

Source:

`finance_targets_2023.xlsx`

The finance dataset contains monthly financial targets by region and product category.

The original structure contains one column for each month.

The data is transformed from wide format into a long analytical structure:

```text
Region | Category | Month | Target Amount

This creates a consistent monthly grain for the target fact table.

The resulting dataset contains:

192 records = 16 Region × Category combinations × 12 months

5.4 ECB Exchange Rates

Source:

ECB historical reference exchange rates.

The exchange-rate dataset provides EUR-based reference rates for currencies including USD and GBP.

For this project, the source is prepared for the 2023 reporting period and only the required currencies are used in the analytical model.

The purpose of the dataset is to convert USD and GBP sales into EUR for consolidated financial analysis.

6. Data Preparation with Dataiku

Dataiku is used as the initial data preparation and ingestion layer.

The main responsibility of Dataiku is to prepare the source datasets before they enter the Snowflake Bronze layer.

6.1 Sales Preparation

The sales source is inspected and prepared before ingestion.

The preparation process addresses source-level formatting issues while preserving the original business information.

Examples include:

Inspecting source columns
Preparing transaction data
Standardizing source formatting
Preserving missing values for downstream treatment
Preparing data for Snowflake ingestion

The detailed business transformations are implemented later in dbt.

6.2 Reviews Preparation

The reviews dataset is prepared for ingestion into Snowflake while retaining the original review information.

The source is kept at review level so that individual customer feedback remains available in the Silver layer.

6.3 Finance Target Preparation

The finance target dataset is prepared for ingestion into Snowflake.

The original monthly structure is preserved at the Bronze stage.

The transformation from wide monthly columns into a long analytical structure is performed in the dbt Silver layer.

This maintains a clear separation between source preparation and analytical modelling.

6.4 ECB Data Preparation

The ECB historical reference dataset is prepared specifically for the project reporting period.

The preparation process:

Loads the original ECB historical reference data.
Selects the required date and currency columns.
Filters the dataset to the 2023 reporting period.
Prepares the resulting dataset for Snowflake ingestion.

The resulting Bronze table is used by the dbt FX staging model.

7. Snowflake Data Warehouse

Snowflake is used as the central cloud data warehouse.

The project uses a dedicated database and separate schemas for the main analytical layers.

7.1 Database

The project database is:

NOVA_RETAIL

The main schemas are:

NOVA_RETAIL.BRONZE
NOVA_RETAIL.SILVER
NOVA_RETAIL.GOLD

This structure separates ingestion, transformation and analytical consumption.

7.2 Warehouse

The project uses:

NOVA_RETAIL_WH

The warehouse is configured as an X-SMALL warehouse with automatic suspension and automatic resume.

The configuration is designed for the scale of the project while avoiding unnecessary compute usage.

8. Bronze Layer

The Bronze layer contains the datasets loaded from Dataiku into Snowflake.

The main tables are:

NOVARETAIL_RAW_SALES_TRANSACTIONS_COPY
NOVARETAIL_WEB_REVIEWS_COPY
NOVARETAIL_FINANCE_TARGETS_2023_COPY
NOVARETAIL_EUROFXREF_HIST_PREPARED_COPY

The Bronze layer acts as the source layer for dbt.

dbt accesses these tables through declared source definitions:

source('nova_bronze', ...)

The Bronze layer does not contain the final business model.

Instead, it provides a stable input layer from which the Silver transformations are built.

9. dbt Transformation Layer

dbt is responsible for the transformation, modelling, testing and documentation of the analytical data.

The dbt project separates source-level transformations from business-oriented analytical models.

The structure is:

models/
├── staging/
└── core/

The transformation flow is:

Snowflake Bronze
       ↓
dbt Staging
       ↓
dbt Core
9.1 Staging Models

The staging models are materialized as views.

The main models are:

stg_sales_transactions
stg_web_reviews
stg_finance_targets
stg_fx_ecb

Staging models use source() to reference Bronze tables.

The main objective of staging is to clean and standardize source data without unnecessarily introducing business-level modelling decisions.

9.2 Sales Staging

stg_sales_transactions standardizes the raw sales dataset.

The model performs several transformations.

Date standardization

Multiple source date formats are handled and converted into a standard DATE field.

Invalid values such as:

Today
NULL

are converted to NULL.

Customer parsing

The original customer field:

Name | Email | Phone

is split into separate fields:

customer_name
customer_email
customer_phone
Currency identification

Currency is identified from the price representation:

$ → USD
€ → EUR
£ → GBP
No symbol → UNKNOWN
Price standardization

Currency symbols and thousands separators are removed before converting the value into a numeric decimal field.

Discount standardization

Discounts are converted into a consistent decimal representation.

For example:

10%  → 0.10
0.15  → 0.15
N/A   → 0
Return identification

Negative quantities are retained and identified through:

is_returned

This avoids modifying the original transaction quantity.

9.3 Reviews Staging

stg_web_reviews standardizes the review dataset.

The model:

Trims textual fields
Standardizes customer information
Converts Unix timestamps
Validates ratings
Preserves review text

Unix timestamps are interpreted according to their length:

10 digits → seconds
13 digits → milliseconds

Ratings outside the expected 1–5 range are converted to NULL.

9.4 Finance Targets Staging

stg_finance_targets transforms the original wide finance dataset into a long structure.

The monthly columns:

Jan-23
Feb-23
Mar-23
Apr-23
May-23
Jun-23
Jul-23
Aug-23
Sep-23
Oct-23
Nov-23
Dec-23

are unpivoted into:

region
category
month
target_amount

This structure is more suitable for analytical queries and dimensional modelling.

9.5 FX Staging

stg_fx_ecb reshapes the prepared ECB data from a wide structure into a long structure.

The model produces:

date_day
currency
rate_to_eur

with separate records for:

USD
GBP

This creates a consistent grain of:

Date + Currency

The model is materialized as a view in the Silver layer.

10. dbt Core Layer

The Core layer contains the final analytical models.

Unlike staging, Core models are materialized as tables.

The Core layer uses ref() to reference staging models:

ref('stg_sales_transactions')
ref('stg_web_reviews')
ref('stg_finance_targets')
ref('stg_fx_ecb')

This creates explicit dbt lineage between the transformation layers:

Bronze → Staging → Core

The Core models are:

dim_date
dim_customer
dim_product
fct_sales
fct_targets
10.1 Why ref() is Used in Core

The Core layer does not read Bronze tables directly.

Instead, Core reads the cleaned staging models using ref().

This provides:

Automatic dependency management
Model lineage
Correct build order
Easier maintenance
Clear separation between cleaning and business modelling

The resulting dependency structure is:

Bronze
   ↓
Staging
   ↓
Core
10.2 Materialization Strategy

The project uses different materializations for the two transformation layers.

Layer	Materialization	Reason
Staging	View	Lightweight cleaned source layer
Core	Table	Persisted analytical models used by BI

Staging transformations are therefore recomputed when queried, while Core models are persisted as tables for analytical consumption.

This follows the project architecture where staging acts as the cleaned source layer and Core provides the served analytical model.


# 11. Gold Data Model

The Gold layer contains the final analytics-ready data model consumed by Power BI.

It follows a simplified star-schema structure with three dimensions and two fact tables.

## 11.1 Gold Models

The Gold layer contains:

### Dimensions

```text
DIM_DATE
DIM_CUSTOMER
DIM_PRODUCT
Facts
FCT_SALES
FCT_TARGETS

The model is designed around the main business questions required by the dashboard:

How much revenue was generated?
How much profit was generated?
How many orders were placed?
What is the average order value?
How is revenue evolving over time?
How does actual revenue compare with financial targets?
How do targets vary by region and product category?
12. Dimension Models
12.1 DIM_DATE

DIM_DATE provides the calendar structure used by the analytical model.

The table contains one row per calendar day for the 2023 reporting period.

Its grain is:

One row = one calendar date

Main attributes include:

date_day
year
month_number
month_name
quarter
week_number
day_of_month
day_of_week
day_name
is_weekday
month_start
quarter_start
year_start

The date dimension is used by Power BI for:

Reporting month selection
Daily analysis
Weekly analysis
Monthly aggregation
MTD calculations
YTD calculations
Time-based filtering

DIM_DATE is related to both fact tables through their date fields.

12.2 DIM_CUSTOMER

DIM_CUSTOMER represents the customer entity used in the sales model.

The customer key is generated from the normalized customer email.

The model normalizes the email by:

Trimming whitespace
Converting the email to lowercase

The normalized email is then hashed using MD5 to create:

customer_key

Main attributes include:

customer_key
customer_email
customer_name
customer_phone

The dimension contains one row per normalized customer email.

This provides a stable analytical key that can be used to connect customer information to the sales fact.

12.3 DIM_PRODUCT

DIM_PRODUCT represents the products included in the sales data.

The product key is generated from the normalized product ID.

Main attributes include:

product_key
product_id
product_category

The product dimension supports Power BI analysis at two levels:

Product Category
        ↓
Product

This enables the required category-to-product drill-down.

13. Fact Models
13.1 FCT_SALES

FCT_SALES is the main transactional fact table used for sales analysis.

Grain

The grain is:

One row = one order

The table contains 100 orders.

The model preserves the original transaction-level information while adding analytical keys and calculated measures.

Main fields include:

order_id
date_day
customer_key
product_key
product_id
product_category
qty
price
price_currency
discount_pct
is_returned
revenue
profit
fx_rate_date
fx_rate_to_eur
revenue_eur
profit_eur
13.2 Revenue Calculation

Revenue is calculated from the transaction price, quantity and discount.

The formula is:

Revenue = Price × Quantity × (1 − Discount)

This calculation is performed in the original transaction currency.

For example:

Price = 1,000
Quantity = 2
Discount = 10%

Revenue = 1,000 × 2 × (1 − 0.10)
        = 1,800
13.3 Profit Calculation

The project assumes a uniform 30% margin on revenue, as specified by the business requirements.

The formula is:

Profit = Revenue × 0.30

This provides a consistent profitability measure across transactions.

The same margin assumption is applied after EUR conversion for:

profit_eur
13.4 Returns

Negative quantities are retained in the sales fact table.

The field:

is_returned

identifies transactions where quantity is negative.

The original quantity is not modified or removed.

This preserves the source transaction while allowing returned orders to be identified during analysis.

14. Currency Standardization

Sales transactions can be recorded in multiple currencies.

The project standardizes USD and GBP transactions into EUR using ECB reference exchange rates.

14.1 Supported Currencies

The sales model contains:

EUR
USD
GBP
UNKNOWN

EUR transactions do not require an external exchange rate.

For EUR transactions:

fx_rate_to_eur = 1

USD and GBP transactions require an applicable ECB rate.

Transactions with an UNKNOWN currency cannot be reliably converted without additional source information.

14.2 FX Matching Logic

For USD and GBP transactions, the model searches for the latest available ECB reference rate on or before the transaction date.

The matching logic is based on:

transaction currency
        +
transaction date
        ↓
latest available ECB rate

This avoids using a future exchange rate for a historical transaction.

The selected FX date is stored in:

fx_rate_date

and the corresponding rate is stored in:

fx_rate_to_eur
14.3 EUR Revenue

ECB rates represent units of the original currency per EUR.

Therefore, the conversion formula is:

Revenue EUR = Revenue in Original Currency / ECB Rate

For example:

USD Revenue / USD per EUR = EUR Revenue

The resulting value is stored in:

revenue_eur
14.4 EUR Profit

Profit is converted using the same FX rate.

The formula is:

Profit EUR = Profit in Original Currency / ECB Rate

The resulting value is stored in:

profit_eur

For EUR transactions, the original profit is retained because the conversion rate is 1.

14.5 Missing FX Conversion

When a valid FX rate cannot be found, the EUR-converted measures remain NULL.

This occurs when:

The transaction date is missing or invalid.
No applicable ECB rate exists in the loaded 2023 reference data.

No exchange rate is estimated or imputed.

This ensures that the analytical model does not introduce unsupported financial values.

15. FCT_TARGETS

FCT_TARGETS contains the financial targets used by the Power BI dashboard.

Grain

The grain is:

Region + Category + Month

Main fields include:

region
category
date_day
target_amount

The monthly target data is created from the unpivoted finance source.

The resulting fact table contains:

192 records

representing:

16 Region × Category combinations
×
12 months
15.1 Target Date

The date_day field represents the first day of the corresponding month.

For example:

January 2023 → 2023-01-01
February 2023 → 2023-02-01
March 2023 → 2023-03-01

This allows monthly targets to be connected to the date dimension through the month-level date.

15.2 Target Currency

The source does not explicitly identify the currency of the target amounts.

Therefore, the project does not assign an unsupported currency to target_amount.

The target values are used consistently for target analysis, while the currency limitation is documented as an assumption.

16. Gold Relationships

The Power BI model uses the following active relationships:

DIM_DATE[date_day]
        1
        │
        *
FCT_SALES[date_day]
DIM_CUSTOMER[customer_key]
        1
        │
        *
FCT_SALES[customer_key]
DIM_PRODUCT[product_key]
        1
        │
        *
FCT_SALES[product_key]
DIM_DATE[date_day]
        1
        │
        *
FCT_TARGETS[date_day]

All relationships use single-direction filtering from the dimensions to the fact tables.

16.1 Why FCT_SALES and FCT_TARGETS Are Not Directly Related

FCT_SALES and FCT_TARGETS have different structures and grains.

Sales data contains:

Order
Date
Customer
Product

Target data contains:

Region
Category
Month

The sales source does not contain region information.

The target dataset therefore cannot be directly joined to sales by region without introducing an unsupported mapping.

Similarly, there is no shared category dimension connecting the sales product category to the target category.

For this reason, no direct relationship between the two fact tables is created.

17. Business Logic Layer

The Gold layer provides the measures required by the Power BI dashboard.

The main Power BI measures are:

Total Revenue
Total Profit
Total Orders
Average Order Value
Total Target
Target Variance
Moving Average Revenue
17.1 Total Revenue

Total Revenue is calculated from EUR-converted sales:

Total Revenue = SUM(FCT_SALES[revenue_eur])

Using EUR-converted revenue allows transactions originally recorded in USD, GBP and EUR to be consolidated into a common currency where a valid conversion is available.

17.2 Total Profit

Total Profit is calculated from EUR-converted profit:

Total Profit = SUM(FCT_SALES[profit_eur])

The calculation uses the project-wide 30% margin assumption.

17.3 Total Orders

The dashboard counts unique orders:

Total Orders = DISTINCTCOUNT(FCT_SALES[order_id])

Because the sales fact has order-level grain, each order is represented once.

17.4 Average Order Value

Average Order Value is calculated as:

AOV = Total Revenue / Total Orders

The Power BI implementation uses:

DIVIDE(
    [Total Revenue],
    [Total Orders]
)

This avoids division errors when no orders are present in the current filter context.

17.5 Total Target

Monthly target amounts are aggregated through:

Total Target = SUM(FCT_TARGETS[target_amount])

This measure is used for monthly and regional target analysis.

17.6 Target Variance

The dashboard includes an indicator showing the distance from the monthly target.

The calculation is:

Target Variance = Total Revenue − Total Target

A positive value indicates that actual revenue is above the target value in the current filter context.

A negative value indicates that actual revenue is below the target value.

The Power BI indicator uses conditional formatting to distinguish positive and negative variance.

18. Time Intelligence

The Power BI dashboard implements the time-intelligence requirements using the DIM_DATE calendar.

The reporting month is selected through:

DIM_DATE[month_start]

This allows the dashboard to operate consistently across the sales and target datasets.

18.1 MTD Revenue

Month-to-Date revenue is calculated using:

MTD Revenue =
CALCULATE(
    [Total Revenue],
    DATESMTD(DIM_DATE[date_day])
)

This returns revenue from the beginning of the current month through the current date context.

18.2 Previous MTD Revenue

Previous MTD revenue is calculated by shifting the MTD date context back one month:

Previous MTD Revenue =
CALCULATE(
    [Total Revenue],
    DATEADD(
        DATESMTD(DIM_DATE[date_day]),
        -1,
        MONTH
    )
)
18.3 MTD Variance %

The percentage variance between MTD and Previous MTD is:

MTD Variance % =
DIVIDE(
    [MTD Revenue] - [Previous MTD Revenue],
    [Previous MTD Revenue]
)

The result is displayed as a percentage.

18.4 YTD Revenue

Year-to-Date revenue is calculated using:

YTD Revenue =
CALCULATE(
    [Total Revenue],
    DATESYTD(DIM_DATE[date_day])
)

Because the available sales dataset only contains 2023, a Previous YTD comparison cannot be calculated from the available historical sales data.

This limitation is documented rather than compensated for through artificial data.

19. Revenue Trend and Moving Average

The dashboard provides a sales trend that can be viewed at two levels of time granularity:

Daily
Weekly

A Power BI field parameter switches the trend axis between:

DIM_DATE[date_day]
DIM_DATE[week_start]

The moving average is controlled through a numeric parameter.

The parameter allows the user to select the number of days used in the moving average.

The current configuration supports:

3–30 days

with a default value of:

7 days

The moving average is calculated dynamically based on the selected parameter.

This allows the same trend visual to provide both the underlying revenue trend and a smoothed view of revenue evolution.

# 20. Power BI Reporting Layer

Power BI is the final consumption layer of the Nova Retail architecture.

The dashboard connects directly to the Snowflake Gold layer and uses the dimensional model created with dbt.

The Power BI model contains the five Gold tables:

```text
DIM_DATE
DIM_CUSTOMER
DIM_PRODUCT
FCT_SALES
FCT_TARGETS

The tables are imported into Power BI and connected using the relationships defined in the Gold model.

21. Power BI Data Model

The Power BI semantic model follows the same star-schema structure implemented in Snowflake.

The main relationships are:

DIM_DATE ──────────── FCT_SALES
    │
    └──────────────── FCT_TARGETS

DIM_CUSTOMER ──────── FCT_SALES

DIM_PRODUCT ────────── FCT_SALES

The dimensions filter the corresponding fact tables using one-to-many relationships.

No direct relationship is created between FCT_SALES and FCT_TARGETS.

This prevents unsupported joins between transactional sales data and regional/category target data.

22. Dashboard KPIs

The main KPI cards provide an executive summary of sales performance.

The dashboard includes:

Total Revenue
Total Profit
Total Orders
Average Order Value

An additional indicator shows:

Distance from Monthly Target

This provides a direct view of the difference between actual revenue and the applicable target in the current reporting context.

22.1 Total Revenue KPI

The Total Revenue KPI displays the sum of EUR-converted revenue:

Total Revenue =
SUM(FCT_SALES[REVENUE_EUR])

Only transactions with an available EUR conversion contribute to the consolidated EUR revenue measure.

22.2 Total Profit KPI

The Total Profit KPI displays the sum of EUR-converted profit:

Total Profit =
SUM(FCT_SALES[PROFIT_EUR])

Profit is based on the 30% margin assumption defined by the project requirements.

22.3 Total Orders KPI

The Total Orders KPI counts unique order IDs:

Total Orders =
DISTINCTCOUNT(FCT_SALES[ORDER_ID])

This avoids double-counting orders.

22.4 Average Order Value KPI

Average Order Value is calculated as:

Average Order Value =
DIVIDE(
    [Total Revenue],
    [Total Orders]
)

This provides the average EUR revenue generated per order in the current filter context.

23. Reporting Month

The dashboard provides a Reporting Month filter based on:

DIM_DATE[MONTH_START]

The filter uses a single-select dropdown.

Selecting a reporting month updates the sales analysis to the corresponding reporting period.

The same date dimension also supports the dashboard's time-intelligence calculations.

24. Dashboard Interactivity

The dashboard provides interactive filtering through the following controls:

Reporting Month
Product Category
Region
Time Granularity
Moving Average Days

These controls allow users to explore the analytical model without changing the underlying data.

24.1 Product Category Filter

The Product Category filter is based on:

DIM_PRODUCT[PRODUCT_CATEGORY]

The filter can be used to analyse sales performance for specific product categories.

It affects the sales-related visuals and KPIs where a product-category context is applicable.

The monthly target visuals are not directly filtered by product category because there is no shared category dimension between the sales and target fact tables.

24.2 Region Filter

The Region filter is based on:

FCT_TARGETS[REGION]

Because regional information exists only in the target dataset, the region filter is applied to target-related analysis.

It does not create a regional breakdown of actual sales.

This reflects the source data structure and avoids inventing a sales-region mapping that is not present in the source data.

24.3 Time Granularity

The revenue trend can be displayed at two levels:

Daily
Weekly

A Power BI field parameter switches the trend axis between:

DIM_DATE[DATE_DAY]
DIM_DATE[WEEK_START]

This allows the same visual to support both detailed daily analysis and higher-level weekly analysis.

24.4 Moving Average Parameter

The dashboard includes a numeric parameter called:

Moving Average Days

The parameter allows the user to select the size of the moving-average window.

The configured range is:

3 to 30 days

with a default value of:

7 days

The moving average is calculated dynamically using the selected number of days.

This provides a smoother representation of the revenue trend while preserving the underlying daily or weekly trend.

25. Target Analysis

The target analysis compares actual sales revenue with the financial targets provided by the finance dataset.

The dashboard includes:

Monthly Target Revenue
Actual Revenue vs Monthly Target
Target Revenue by Region
Distance from Monthly Target
25.1 Monthly Target Revenue

The monthly target visual uses:

FCT_TARGETS[DATE_DAY]

as the time axis and:

[Total Target]

as the target measure.

The visual displays the monthly target values across the 2023 reporting period.

25.2 Actual Revenue vs Monthly Target

The dashboard compares:

Actual Revenue

with:

Monthly Target Revenue

Actual revenue is represented by:

[Total Revenue]

and target revenue by:

[Total Target]

The visual uses the common monthly time context provided by the date dimension.

25.3 Target Revenue by Region

Target revenue is also analysed by region using:

FCT_TARGETS[REGION]

and:

[Total Target]

This visual describes the regional distribution of financial targets.

It does not represent actual sales by region because the sales source does not contain regional information.

25.4 Distance from Monthly Target

The dashboard provides a visual indicator of the difference between actual revenue and target revenue.

The calculation is:

Target Variance =
[Total Revenue] - [Total Target]

The result is conditionally formatted so that:

Negative variance → below target
Non-negative variance → at or above target

The indicator is intended to provide a quick view of the distance from the target in the selected reporting context.

26. Revenue by Product

The dashboard includes a product revenue visual using:

DIM_PRODUCT[PRODUCT_CATEGORY]
DIM_PRODUCT[PRODUCT_ID]

and:

[Total Revenue]

The visual supports drill-down from:

Product Category
        ↓
Product

This allows users to move from an aggregated category view to individual products.

The drill-down uses the product hierarchy available in DIM_PRODUCT.

27. Dashboard Reset

A Reset Filters button is included in the dashboard.

The button allows users to return the report to its default filter state after exploring different combinations of:

Reporting month
Product category
Region
Time granularity
Moving-average window

This improves usability when navigating the interactive dashboard.

28. Time Intelligence Implementation

The project implements reusable time-intelligence logic in Power BI through a calculation group.

The calculation group is:

Time Intelligence

The implemented calculation items include:

MTD
Previous MTD
MTD Variance
MTD Variance %
YTD
YTD Variance

The calculation group uses SELECTEDMEASURE() so that the same time-intelligence logic can be applied to compatible measures.

The project also contains explicit revenue measures for MTD and YTD reporting where required by the dashboard.

28.1 Calculation Group Consideration

The calculation group remains part of the semantic model, while the main dashboard does not use a Time Intelligence slicer.

This avoids applying a time-intelligence transformation unintentionally to every KPI or visual on the page.

The dashboard instead uses the explicit measures and standard measures required for each visual.

29. Data Quality Validation

Data quality is validated at multiple stages of the pipeline.

Validation takes place through:

Dataiku
    ↓
Snowflake
    ↓
dbt tests
    ↓
Power BI model validation

The dbt project contains both generic and singular tests.

29.1 Generic dbt Tests

Generic tests validate common structural properties such as:

not_null
unique
relationships
accepted_values

These tests are applied to important dimensions, facts and staging models.

Examples include:

Unique date keys
Unique customer keys
Unique product keys
Unique order IDs
Valid currency values
Referential integrity between facts and dimensions
29.2 Singular dbt Tests

Project-specific business rules are validated through singular tests.

The project includes tests for:

fct_targets_unique_grain
fct_targets_positive_amount
stg_fx_ecb_unique_grain
fct_sales_fx_conversion

These tests validate business-specific conditions that cannot be fully represented by generic tests.

29.3 Build Validation

The complete dbt project has been successfully built with:

dbt build

All current models and tests pass successfully.

This validates the dependency graph, model compilation, table creation and configured data-quality tests.

30. Data Lineage

The dbt project provides explicit lineage from the Bronze layer through the final analytical models.

The lineage follows:

Snowflake Bronze
       ↓
dbt Sources
       ↓
dbt Staging
       ↓
dbt Core
       ↓
Power BI

The staging layer references Bronze using:

source()

The Core layer references staging models using:

ref()

This makes model dependencies explicit and allows dbt to determine the appropriate build order.

31. Documentation and Reproducibility

The project documentation is maintained alongside the analytical code.

The GitHub repository contains the main project documentation:

README.md
DATA_QUALITY.md
GOLD_ERD.md
TECHNICAL_DOCUMENTATION.md

The documentation describes:

Project architecture
Data sources
Data preparation
Snowflake structure
dbt transformations
Gold data model
Business logic
Data quality
Known limitations
Analytical assumptions

Keeping the documentation in the same repository as the project improves traceability and reproducibility.

32. Known Analytical Limitations

The final analytical model has several limitations resulting directly from the available source data.

These limitations are intentionally documented rather than hidden.

Sales dates

Seven sales records have missing or invalid transaction dates.

These records remain in the data but cannot be assigned to a specific reporting date.

Unknown currencies

Three sales records have no identifiable currency symbol.

Their currency is therefore classified as:

UNKNOWN

and they are not converted into EUR.

Missing EUR conversions

Eight sales records do not have EUR-converted revenue.

The reasons are documented in the Data Quality documentation.

Regional sales analysis

The sales source does not contain region information.

Therefore, actual sales cannot be reliably analysed by region without an additional mapping source.

Target currency

The finance target source does not explicitly specify the currency of the target amounts.

The project therefore does not present a specific target currency as a confirmed source attribute.

Previous-year comparison

The available sales data covers 2023 only.

Therefore, a true Previous YTD comparison cannot be calculated from the available sales history.

Fact table relationship

FCT_SALES and FCT_TARGETS are not directly related because their available business keys do not provide a valid shared dimensional path for both region and category.

33. Final Architecture Summary

The completed Nova Retail solution follows the architecture:

┌──────────────────────────────┐
│       LOCAL DATA SOURCES     │
│                              │
│ Sales CSV                    │
│ Reviews JSON                 │
│ Finance Targets XLSX         │
│ ECB FX Reference Data        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│           DATAIKU            │
│                              │
│ Data preparation             │
│ Source inspection            │
│ Initial transformations      │
│ FX preparation               │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│      SNOWFLAKE BRONZE        │
│                              │
│ Prepared source datasets     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│           DBT SILVER         │
│                              │
│ Cleaning                     │
│ Standardization              │
│ Validation                   │
│ Source-level transformations │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│            DBT GOLD          │
│                              │
│ DIM_DATE                     │
│ DIM_CUSTOMER                 │
│ DIM_PRODUCT                  │
│ FCT_SALES                    │
│ FCT_TARGETS                  │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│           POWER BI           │
│                              │
│ Executive KPIs               │
│ Sales trends                 │
│ Moving average               │
│ MTD / YTD analysis           │
│ Target analysis              │
│ Category / product drilldown │
│ Interactive filters          │
└──────────────────────────────┘

The resulting solution provides a complete analytical workflow from raw multi-source data to a tested dimensional model and interactive business intelligence dashboard.

The architecture separates ingestion, storage, transformation, modelling and reporting responsibilities while documenting the assumptions and limitations introduced by the available source data.


# 34. Project Deliverables

The Nova Retail project produces the following main deliverables:

## 34.1 Technical Documentation

The technical documentation describes the complete analytical solution, including:

- Data architecture
- Data sources
- Data preparation
- Snowflake implementation
- dbt transformation layers
- Gold data model
- Business logic
- Power BI implementation
- Data quality validation
- Known assumptions and limitations

---

## 34.2 Data Quality Documentation

`DATA_QUALITY.md` documents the main source-data issues and the rules used to handle them.

It includes:

- Sales data quality
- Review data quality
- Finance target structure
- FX conversion rules
- dbt data-quality tests
- Modelling decisions
- Known limitations and assumptions

---

## 34.3 Gold ERD

`GOLD_ERD.md` documents the analytical entity relationship diagram for the Gold layer.

The model contains:

```text id="i0o6x2"
DIM_DATE
DIM_CUSTOMER
DIM_PRODUCT
FCT_SALES
FCT_TARGETS

The ERD describes the relationships between dimensions and fact tables and documents the main grain of each model.

34.4 dbt Project

The repository contains the dbt project used to build the Silver and Gold layers.

The dbt project includes:

dbt_project.yml
models/
macros/
tests/

The project contains:

Source definitions
Staging models
Core models
Generic tests
Singular tests
Schema documentation
Custom schema generation logic
34.5 Power BI Dashboard

The Power BI deliverable contains the final interactive dashboard built from the Snowflake Gold layer.

The dashboard provides:

Executive KPIs
Reporting month filtering
Product category filtering
Region filtering
Daily and weekly revenue trends
Dynamic moving average
MTD analysis
YTD analysis
Actual versus target analysis
Regional target analysis
Category-to-product drill-down
Target variance indicator
Reset filters functionality
34.6 GitHub Repository

The GitHub repository contains the project documentation and analytical transformation code.

The repository provides a central location for:

Project documentation
dbt models
dbt tests
Macros
Data-quality documentation
Gold model documentation
Project configuration

This structure allows the analytical workflow to be reviewed and reproduced from the documented project components.

35. Recommended Repository Structure

The final repository is organized around the main project components.

A simplified structure is:

nova-retail/
│
├── README.md
├── DATA_QUALITY.md
├── GOLD_ERD.md
├── TECHNICAL_DOCUMENTATION.md
│
├── dbt_project.yml
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
│   ├── sources.yml
│   └── schema.yml
│
├── macros/
│   └── generate_schema_name.sql
│
└── tests/
    ├── fct_targets_unique_grain.sql
    ├── fct_targets_positive_amount.sql
    ├── stg_fx_ecb_unique_grain.sql
    └── fct_sales_fx_conversion.sql

The exact repository contents may also include additional project files generated by the dbt environment.

The structure above represents the main analytical components of the solution.

36. Final Project Outcome

Nova Retail implements a complete end-to-end data analytics workflow.

The solution transforms heterogeneous source data through a controlled sequence of preparation, storage, transformation, validation and reporting stages:

Local Sources
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

The resulting Gold layer provides a structured analytical model containing:

DIM_DATE
DIM_CUSTOMER
DIM_PRODUCT
FCT_SALES
FCT_TARGETS

The model is validated through dbt tests and documented data-quality rules.

Power BI then exposes the resulting analytical model through an interactive dashboard covering the required sales KPIs, time analysis, moving averages, product analysis and financial target comparisons.

The project demonstrates the integration of:

Data Preparation
      +
Cloud Data Warehousing
      +
SQL Transformation
      +
Dimensional Modelling
      +
Data Quality
      +
Business Intelligence

The architecture provides a traceable path from source data to business reporting while explicitly documenting the assumptions and limitations of the available data.