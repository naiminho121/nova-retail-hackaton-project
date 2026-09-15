with source as (

    select *
    from {{ source('nova_bronze', 'NOVARETAIL_WEB_REVIEWS_COPY') }}

),

cleaned as (

    select

        -- Review identifier
        trim("review_id") as review_id,

        -- Product reference
        trim("product_ref") as product_ref,

        -- Customer information
        trim("user.name") as customer_name,
        trim("user.email") as customer_email,

        -- Customer location
        trim("user.location.country") as country,
        trim("user.location.city") as city,

        -- Convert Epoch timestamp to datetime
        case
            when "timestamp" is null
                or trim("timestamp") = ''
                or lower(trim("timestamp")) = 'null'
                then null

            -- Milliseconds
            when try_to_number(trim("timestamp")) >= 1000000000000
                then to_timestamp_ntz(
                    try_to_number(trim("timestamp")) / 1000
                )

            -- Seconds
            else to_timestamp_ntz(
                try_to_number(trim("timestamp"))
            )
        end as review_timestamp,

        -- Standardize rating
        case
            when try_to_number(trim("rating")) between 1 and 5
                then try_to_number(trim("rating"))
            else null
        end as rating,

        -- Review text
        trim("review_text") as review_text

    from source

)

select *
from cleaned