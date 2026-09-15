select
    region,
    category,
    date_day,
    target_amount
from {{ ref('fct_targets') }}
where target_amount < 0