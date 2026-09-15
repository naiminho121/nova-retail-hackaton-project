select
    region,
    category,
    date_day,
    count(*) as row_count

from {{ ref('fct_targets') }}

group by
    region,
    category,
    date_day

having count(*) > 1