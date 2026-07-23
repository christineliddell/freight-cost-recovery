with source as (

    select * from {{ source('olist', 'customers') }}

),

renamed as (

    select
        customer_id,
        customer_unique_id,
        lpad(cast(customer_zip_code_prefix as varchar), 5, '0') as customer_zip_prefix,
        customer_city,
        customer_state

    from source

)

select * from renamed