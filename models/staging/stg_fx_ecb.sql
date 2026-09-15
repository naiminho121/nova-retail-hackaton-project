{{ config(materialized='view') }}

with fx as (

    select
        "Date" as date_day,
        "USD" as usd_rate_to_eur,
        "GBP" as gbp_rate_to_eur
    from {{ source('nova_bronze', 'NOVARETAIL_EUROFXREF_HIST_PREPARED_COPY') }}

),

final as (

    select
        date_day,
        'USD' as currency,
        usd_rate_to_eur as rate_to_eur
    from fx

    union all

    select
        date_day,
        'GBP' as currency,
        gbp_rate_to_eur as rate_to_eur
    from fx

)

select *
from final