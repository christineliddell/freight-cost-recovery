with source as (

    select * from {{ source('olist', 'order_items') }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as shipment_key,

        order_id,
        order_item_id                             as order_item_number,
        product_id,
        seller_id,

        cast(shipping_limit_date as timestamp)    as shipping_limit_at,
        cast(price as decimal(10, 2))             as item_price_brl,
        cast(freight_value as decimal(10, 2))     as freight_cost_brl

    from source

)

select * from renamed