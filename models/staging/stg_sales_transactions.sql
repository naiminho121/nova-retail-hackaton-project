with source as (

    select *
    from {{ source('nova_bronze', 'NOVARETAIL_RAW_SALES_TRANSACTIONS_COPY') }}

),

cleaned as (

    select

        -- Order identifier
        "order_id" as order_id,

        -- Standardize transaction date
        case
            when "transaction_date" is null
                or trim("transaction_date") = ''
                or upper(trim("transaction_date")) = 'TODAY'
                then null

            -- ISO format: 2023-03-23
            when "transaction_date" like '____-__-__'
                then try_to_date(
                    trim("transaction_date"),
                    'YYYY-MM-DD'
                )

            -- Alternative ISO format: 2023/10/09
            when "transaction_date" like '____/__/__'
                then try_to_date(
                    trim("transaction_date"),
                    'YYYY/MM/DD'
                )

            -- Text month format: 15-Oct-2023
            when "transaction_date" like '%-___-____'
                then try_to_date(
                    trim("transaction_date"),
                    'DD-MON-YYYY'
                )

            -- Slash format where first value > 12:
            -- DD/MM/YYYY
            when try_to_number(
                    split_part(trim("transaction_date"), '/', 1)
                 ) > 12
                then try_to_date(
                    trim("transaction_date"),
                    'DD/MM/YYYY'
                )

            -- Slash format where second value > 12:
            -- MM/DD/YYYY
            when try_to_number(
                    split_part(trim("transaction_date"), '/', 2)
                 ) > 12
                then try_to_date(
                    trim("transaction_date"),
                    'MM/DD/YYYY'
                )

            -- Ambiguous slash dates:
            -- Assume DD/MM/YYYY
            else try_to_date(
                trim("transaction_date"),
                'DD/MM/YYYY'
            )
        end as transaction_date,

        -- Split customer information
        trim(split_part("customer_info", '|', 1)) as customer_name,
        trim(split_part("customer_info", '|', 2)) as customer_email,
        trim(split_part("customer_info", '|', 3)) as customer_phone,

        -- Product information
        trim("product_id") as product_id,
        trim("product_category") as product_category,

        -- Identify currency from original price
        case
            when trim("price") like '$%' then 'USD'
            when trim("price") like '€%' then 'EUR'
            when trim("price") like '£%' then 'GBP'
            else 'UNKNOWN'
        end as price_currency,

        -- Clean price
        try_to_decimal(
            replace(
                replace(
                    replace(
                        replace(
                            trim("price"),
                            '$',
                            ''
                        ),
                        '€',
                        ''
                    ),
                    '£',
                    ''
                ),
                ',',
                ''
            ),
            18,
            2
        ) as price,

        -- Quantity
        try_to_number("qty") as qty,

        -- Identify returned transactions
        try_to_number("qty") < 0 as is_returned,

        -- Standardize discount to decimal
        case
            when "discount_pct" is null
                or trim("discount_pct") = ''
                or upper(trim("discount_pct")) in ('N/A', 'NA', 'NULL')
                then 0

            when contains(trim("discount_pct"), '%')
                then try_to_decimal(
                    replace(
                        trim("discount_pct"),
                        '%',
                        ''
                    )
                ) / 100

            else try_to_decimal(
                trim("discount_pct")
            )
        end as discount_pct

    from source

)

select *
from cleaned