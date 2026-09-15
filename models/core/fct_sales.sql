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

),

sales_with_fx as (

    select
        s.*,
        fx.date_day as fx_rate_date,
        fx.rate_to_eur as fx_rate_to_eur,

        row_number() over (
            partition by s.order_id
            order by fx.date_day desc
        ) as fx_rank

    from sales s

    left join {{ ref('stg_fx_ecb') }} fx
        on fx.currency = s.price_currency
        and fx.date_day <= s.transaction_date

),

final as (

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

        s.price * s.qty * (1 - s.discount_pct) * 0.30 as profit,

        case
            when s.price_currency = 'EUR'
                then s.transaction_date
            else s.fx_rate_date
        end as fx_rate_date,

        case
            when s.price_currency = 'EUR'
                then 1
            when s.price_currency in ('USD', 'GBP')
                then s.fx_rate_to_eur
            else null
        end as fx_rate_to_eur,

        case
            when s.price_currency = 'EUR'
                then s.price * s.qty * (1 - s.discount_pct)

            when s.price_currency in ('USD', 'GBP')
                and s.fx_rate_to_eur is not null
                then
                    (s.price * s.qty * (1 - s.discount_pct))
                    / s.fx_rate_to_eur

            else null
        end as revenue_eur,

        case
            when s.price_currency = 'EUR'
                then s.price * s.qty * (1 - s.discount_pct) * 0.30

            when s.price_currency in ('USD', 'GBP')
                and s.fx_rate_to_eur is not null
                then
                    (s.price * s.qty * (1 - s.discount_pct) * 0.30)
                    / s.fx_rate_to_eur

            else null
        end as profit_eur

    from sales_with_fx s

    left join customers c
        on lower(trim(s.customer_email)) = c.customer_email

    left join products p
        on trim(s.product_id) = p.product_id

    where s.fx_rank = 1
       or s.fx_rank is null

)

select *
from final