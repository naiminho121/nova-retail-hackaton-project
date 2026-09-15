select
    order_id,
    price_currency,
    fx_rate_to_eur,
    revenue_eur
from {{ ref('fct_sales') }}
where price_currency in ('USD', 'GBP')
  and fx_rate_to_eur is not null
  and revenue_eur is null