# Nova Retail — Data Quality & Transformation Log

## 1. Sales Transactions

Source: `raw_sales_transactions.csv`

| Field | Data Quality Issue | Treatment |
|---|---|---|
| `transaction_date` | Mixed date formats, null values and the literal value `Today` were present. | Standardized valid values to `DATE`. `Today` and missing values are converted to `NULL`. |
| `customer_info` | Customer name, email and phone were stored together in a single pipe-separated field. | Split into `customer_name`, `customer_email` and `customer_phone`. |
| `price` | Values contained different currency symbols and formatting, including `$`, `€`, `£`, commas and spaces. | Currency symbols and formatting characters were removed and the value was converted to a numeric field. The original currency is preserved in `price_currency`. No FX conversion was applied because exchange rates were not provided. |
| `qty` | A negative quantity was present. | Negative quantities are preserved and flagged through `is_returned = TRUE`. |
| `discount_pct` | Mixed representations including decimals, percentages and `N/A` values. | Standardized to decimal format. Missing, empty and `N/A` values are treated as `0`. |

### Sales validation

- 100 source transactions were retained.
- 100 distinct `order_id` values were identified.
- 1 transaction contains a negative quantity and is flagged as a return.
- 7 transactions have no usable transaction date because of missing values or the literal `Today`.
- No transaction was removed solely because of a missing date.
- All transactions have a valid numeric quantity.
- All transactions have a valid numeric price after standardization.

---

## 2. Web Reviews

Source: `web_reviews.json`

The nested JSON structure was flattened during ingestion to expose customer, product, timestamp and review attributes.

| Field | Data Quality Issue | Treatment |
|---|---|---|
| `timestamp` | Timestamps were provided using both seconds and milliseconds. | Timestamp precision is detected from the value and normalized to `TIMESTAMP`. |
| `rating` | Missing and invalid rating values were present. | Only ratings between 1 and 5 are retained. Invalid or missing values are standardized to `NULL`. |
| Customer information | Customer information was nested inside the JSON structure. | Relevant customer attributes were flattened into separate columns. |

### Reviews validation

- 60 reviews were processed.
- 0 missing timestamps remain after normalization.
- 12 reviews have a missing or invalid standardized rating.
- No invalid rating outside the accepted 1–5 range remains as a populated value.

Reviews are retained in the Silver layer because they are part of the available source data. They are not included in the Gold analytical model because the required executive dashboard does not contain review-related KPIs or visualizations.

---

## 3. Finance Targets

Source: `finance_targets_2023.xlsx` / CSV representation

| Field / Structure | Data Quality Issue | Treatment |
|---|---|---|
| `Region` | The first block of source records contained missing region values. | Missing values were assigned `NA` based on the structure of the source data. This assumption is documented rather than silently discarded. |
| Monthly target columns | Targets were stored in a wide format with one column per month. | Data was unpivoted into one row per Region, Category and Month. |
| Target values | Target amounts required numeric standardization. | Values were converted to a numeric decimal representation. |

### Finance validation

The source contains:

- 16 Region/Category combinations.
- 12 monthly target columns.
- 192 rows after unpivoting.

The resulting Gold fact table has a defined grain of:

> **One row per Region + Category + Month.**

A dedicated dbt test validates that this grain is unique.

---

## 4. Bronze → Silver → Gold Strategy

The project follows a Medallion-style architecture.

### Bronze

Bronze contains the raw data ingested from the original local files with minimal structural changes.

Sources:

- Sales transactions
- Web reviews
- Finance targets

The objective of Bronze is to preserve the original source information and provide a controlled landing layer.

### Silver

Silver contains cleaned and standardized data.

Main transformations include:

- Data type standardization
- Date normalization
- Customer information parsing
- Currency and price cleaning
- Discount standardization
- Return identification
- Review timestamp normalization
- Review rating validation
- Finance target unpivoting

### Gold

Gold contains the business-ready dimensional model used for analytics and BI.

The model consists of:

- `DIM_DATE`
- `DIM_CUSTOMER`
- `DIM_PRODUCT`
- `FCT_SALES`
- `FCT_TARGETS`

The Gold layer is designed specifically to support the required executive dashboard.

---

## 5. Data Quality Testing

dbt tests are used to validate the Gold layer.

Current tests cover:

- Not-null constraints
- Uniqueness constraints
- Foreign-key relationships
- `FCT_TARGETS` grain uniqueness

Key validations include:

- `DIM_DATE.date_day` is unique and not null.
- `DIM_CUSTOMER.customer_key` is unique and not null.
- `DIM_PRODUCT.product_key` and `product_id` are unique and not null.
- `FCT_SALES.order_id` is unique and not null.
- Sales customer and product keys have valid relationships with their dimensions.
- `FCT_TARGETS` contains no duplicate Region + Category + Month combinations.

All configured dbt tests pass successfully.

---

## 6. Schema Drift Strategy

Schema drift is handled by separating raw ingestion from transformation logic.

### Bronze

New or changed source fields should first land in Bronze without being silently discarded.

### Silver

The staging models explicitly select and transform the fields required by the analytical model. Changes to source field names, formats or data types can therefore be identified and handled during the Silver transformation layer.

### Gold

Gold models expose only business-ready fields required for analytics and reporting. This prevents unexpected source changes from directly affecting the BI layer.

If a source schema changes, the recommended process is:

1. Identify the changed or new field in the Bronze layer.
2. Assess its impact on the Silver transformation.
3. Update the relevant dbt staging model.
4. Update tests and documentation where required.
5. Validate the Gold model.
6. Re-run dbt tests before exposing the changes to Power BI.

---

## 7. Assumptions & Limitations

### Currency

Sales contain multiple currencies (`USD`, `EUR`, `GBP` and unknown/bare numeric values).

No exchange-rate source was provided, therefore no currency conversion was performed. The original currency is preserved in `price_currency`.

Revenue and profit should therefore be interpreted within the currency context of each transaction unless an external FX source is introduced.

### Profit

Profit is calculated using the uniform **30% margin assumption specified in the project brief**:

`Profit = Revenue × 30%`

### Missing transaction dates

Transactions with missing or unresolved dates are retained rather than deleted. Their `date_day` remains `NULL`.

This preserves the original transaction records while preventing uncertain dates from being artificially assigned.

### Region

Sales transactions do not contain a region field. Region is therefore available only in the Finance Targets dataset.

No artificial relationship between sales and target regions has been created.

### Reviews

Reviews are cleaned and retained in Silver but are not included in the Gold model because they are not required by the specified executive dashboard.

---

## 8. Summary

The data pipeline transforms three heterogeneous source datasets into a tested and documented analytical model:

**Local Files → Dataiku → Snowflake Bronze → dbt Silver → dbt Gold → Power BI**

Data quality issues are handled explicitly rather than silently removing records, and the Gold layer is protected through dbt testing and documentation.