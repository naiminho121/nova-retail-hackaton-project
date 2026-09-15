{{ config(materialized='table') }}

with dates as (
    select
        dateadd(
            day,
            row_number() over (order by seq4()) - 1,
            '2023-01-01'::date
        ) as date_day
    from table(generator(rowcount => 365))
)

select
    date_day,
    year(date_day) as year,
    month(date_day) as month_number,
    monthname(date_day) as month_name,
    quarter(date_day) as quarter,
    week(date_day) as week_number,
    day(date_day) as day_of_month,
    dayofweek(date_day) as day_of_week,
    dayname(date_day) as day_name,
    case
        when dayofweek(date_day) in (1, 7) then false
        else true
    end as is_weekday,
    date_trunc('month', date_day) as month_start,
    date_trunc('quarter', date_day) as quarter_start,
    date_trunc('year', date_day) as year_start

from dates