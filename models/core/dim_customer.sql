{{ config(materialized='table') }}

select
    md5(lower(trim(customer_email))) as customer_key,
    lower(trim(customer_email)) as customer_email,
    max(customer_name) as customer_name,
    max(customer_phone) as customer_phone

from {{ ref('stg_sales_transactions') }}

where customer_email is not null
  and trim(customer_email) <> ''

group by lower(trim(customer_email))