with source as (

    select *
    from {{ source('nova_bronze', 'NOVARETAIL_FINANCE_TARGETS_2023_COPY') }}

),

unpivoted as (

    select
        trim("Region") as region,
        trim("Category") as category,
        "Jan-23",
        "Feb-23",
        "Mar-23",
        "Apr-23",
        "May-23",
        "Jun-23",
        "Jul-23",
        "Aug-23",
        "Sep-23",
        "Oct-23",
        "Nov-23",
        "Dec-23"
    from source

),

final as (

    select
        region,
        category,
        to_date(month_name, 'MON-YY') as month,
        try_to_decimal(target_amount, 18, 2) as target_amount
    from unpivoted
    unpivot (
        target_amount for month_name in (
            "Jan-23",
            "Feb-23",
            "Mar-23",
            "Apr-23",
            "May-23",
            "Jun-23",
            "Jul-23",
            "Aug-23",
            "Sep-23",
            "Oct-23",
            "Nov-23",
            "Dec-23"
        )
    )

)

select *
from final