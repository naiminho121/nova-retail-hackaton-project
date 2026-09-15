{{ config(materialized='table') }}

select
    md5(trim(product_id)) as product_key,
    trim(product_id) as product_id,
    trim(product_category) as product_category

from {{ ref('stg_sales_transactions') }}

where product_id is not null
  and trim(product_id) <> ''

group by
    trim(product_id),
    trim(product_category)