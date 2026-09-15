{{ config(materialized='table') }}

with sales as (

    select *
    from {{ ref('stg_sales_transactions') }}

),

customers as (

    select
        customer_key,
        customer_email
    from {{ ref('dim_customer') }}

),

products as (

    select
        product_key,
        product_id
    from {{ ref('dim_product') }}

)

select
    s.order_id,

    s.transaction_date as date_day,

    c.customer_key,

    p.product_key,

    s.product_id,
    s.product_category,

    s.qty,
    s.price,
    s.price_currency,
    s.discount_pct,
    s.is_returned,

    s.price * s.qty * (1 - s.discount_pct) as revenue,

    s.price * s.qty * (1 - s.discount_pct) * 0.30 as profit

from sales s

left join customers c
    on lower(trim(s.customer_email)) = c.customer_email

left join products p
    on trim(s.product_id) = p.product_id