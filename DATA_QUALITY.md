# Nova Retail — Data Quality

This document describes the main data quality checks, cleaning rules and assumptions applied throughout the Nova Retail data pipeline.

## 1. Sales Transactions

### Source

`raw_sales_transactions.csv`

### Volume

- 100 sales records
- 100 unique orders

### Main data quality issues

#### Transaction dates

The source contains multiple date formats and invalid or missing values, including:

- ISO format
- Different slash-based formats
- Text values such as `Today`
- Null values

The staging model standardizes valid dates into the `DATE` data type.

After cleaning, **7 records have a missing or invalid transaction date**.

These records are retained in the dataset rather than removed.

#### Customer information

Customer information is originally stored in a single pipe-separated field:

```text
Name | Email | Phone

The staging layer splits this field into:

customer_name
customer_email
customer_phone

Customer emails are normalized to lowercase and trimmed before being used to generate the customer key.

Price and currency

The source contains prices with different currency formats:

$ → USD
€ → EUR
£ → GBP
Numeric values without a currency symbol → UNKNOWN

The currency is stored separately in price_currency.

The numeric price value is cleaned and converted into a decimal field.

Three sales records have an UNKNOWN currency because the original source does not provide enough information to determine their currency.

These records are retained.

Quantity

Quantity is converted into a numeric field.

One transaction contains a negative quantity and is identified as a return through:

is_returned

The original quantity is retained rather than removed or corrected.

Discounts

Discount values appear in different formats, including decimal values, percentages and missing/N/A values.

They are standardized to decimal representation.

Examples:

10% → 0.10
0.15 → 0.15
N/A → 0
2. Web Reviews
Source

web_reviews.json

Volume
60 review records
Timestamp

The source contains both:

10-digit Unix timestamps
13-digit Unix timestamps

The staging model detects the timestamp format and converts both into a standard timestamp.

Ratings

Ratings are expected to be between 1 and 5.

Invalid or missing ratings are converted to NULL.

After cleaning, 12 reviews have missing ratings.

The review records are retained.

3. Finance Targets
Source

finance_targets_2023.xlsx

Source structure

The original dataset is provided in a wide monthly format.

The staging model transforms it into a long format containing:

region
category
month
target_amount
Grain

The target fact table has the following grain:

Region + Category + Month

The resulting dataset contains:

16 Region × Category combinations × 12 months = 192 records

Missing Region

The first four source rows contain missing Region values.

These values were assigned NA based on the structure of the source dataset.

This is documented as a project assumption rather than a confirmed source value.

Target currency

The source does not explicitly specify the currency of target_amount.

Therefore, the target currency should be treated as an assumption and should not be presented as a confirmed source attribute.

4. Foreign Exchange Rates
Source

ECB historical reference exchange rates.

The source data was filtered to the 2023 reporting period before being loaded into Snowflake Bronze.

Purpose

The FX data is used to standardize USD and GBP sales into EUR so that global financial KPIs can be compared using a common currency.

Currencies used

The project uses:

USD
GBP

EUR transactions use an exchange rate of 1.

Rate definition

ECB rates represent the amount of the original currency corresponding to one EUR.

Therefore:

Revenue EUR = Revenue in Original Currency / ECB Rate
FX date matching

For USD and GBP transactions, the model uses the latest available ECB reference rate on or before the transaction date.

This is implemented using:

fx_rate_date
fx_rate_to_eur
Missing FX rates

Some transactions cannot be converted to EUR because:

The transaction date is missing, or
No applicable ECB rate is available in the loaded 2023 dataset.

In these cases:

revenue_eur = NULL
profit_eur = NULL

The original transaction values and calculated revenue and profit in the source currency are retained.

No FX rate is estimated or imputed.

Current conversion coverage

The resulting FCT_SALES table contains:

100 total orders
92 orders with EUR-converted revenue
8 orders without EUR-converted revenue

The 8 orders without EUR-converted revenue consist of:

7 orders with missing or invalid transaction dates.
1 USD order dated 2023-01-01 for which no applicable ECB rate is available in the loaded 2023 dataset.

The missing conversions are intentional and traceable to the conditions described above.

5. dbt Data Quality Tests

The project uses both generic and singular dbt tests.

Generic tests

Generic tests provide systematic validation of key columns.

Examples include:

not_null
unique
relationships
accepted_values
Singular tests

Singular tests are used for project-specific business rules.

Current singular tests include:

fct_targets_unique_grain

Checks that there are no duplicate combinations of:

region + category + date_day
fct_targets_positive_amount

Checks that target amounts are not negative.

stg_fx_ecb_unique_grain

Checks that there is only one FX rate for each:

date_day + currency
fct_sales_fx_conversion

Checks that USD and GBP transactions with an available FX rate produce a non-NULL EUR revenue value.

All current dbt models and tests pass successfully.

6. Data Modelling Decisions
Bronze

Bronze contains raw or minimally prepared source data loaded from Dataiku into Snowflake.

Silver

Silver contains cleaned and standardized source-level data.

Examples include:

Date standardization
Customer field splitting
Currency identification
Discount normalization
Review timestamp normalization
Finance target unpivoting
FX reshaping
Gold

Gold contains analytics-ready dimensional and fact models:

DIM_DATE
DIM_CUSTOMER
DIM_PRODUCT
FCT_SALES
FCT_TARGETS
Reviews

Web reviews remain in the Silver layer because they are not required for the current Power BI reporting scope.

Regional sales analysis

The sales source does not contain region information.

Therefore, no sales region has been inferred or artificially created.

Regional information exists only in the target dataset.

As a result, regional target comparisons require an appropriate regional mapping if they are to be extended to actual sales performance.

7. Known Limitations and Assumptions

The following points should be considered when interpreting the Gold layer:

Seven sales records have missing or invalid transaction dates.
Three sales records have an UNKNOWN currency.
Eight sales records do not have EUR-converted revenue.
Four finance target records have Region assigned as NA based on the source structure.
The currency of finance targets is not explicitly specified by the source.
ECB FX rates are limited to the loaded 2023 reference data.
No sales region has been inferred because the sales source does not contain regional information.
FCT_TARGETS has a monthly grain, while FCT_SALES has an order-level grain.
There is no direct relationship between sales and targets by category or region in the current Gold model.
EUR-converted measures should be used for cross-currency financial analysis where available.

These limitations are intentionally documented rather than hidden or corrected through unsupported assumptions.