{{ config(materialized='table') }}

select
    region,
    category,
    month as date_day,
    target_amount

from {{ ref('stg_finance_targets') }}