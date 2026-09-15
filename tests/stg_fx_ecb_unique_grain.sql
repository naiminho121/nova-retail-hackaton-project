select
    date_day,
    currency,
    count(*) as row_count
from {{ ref('stg_fx_ecb') }}
group by
    date_day,
    currency
having count(*) > 1