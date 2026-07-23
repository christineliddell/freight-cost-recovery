{{ config(materialized = 'table') }}

with shipments as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

sellers as (
    select * from {{ ref('stg_sellers') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

geo as (
    select * from {{ ref('stg_geolocation') }}
),

joined as (

    select
        shipments.shipment_key,
        shipments.order_id,
        shipments.order_item_number,
        shipments.product_id,
        shipments.seller_id,

        orders.customer_id,
        orders.order_status,
        orders.purchased_at,
        orders.delivered_at,
        orders.promised_delivery_at,

        sellers.seller_state,
        customers.customer_state,

        seller_geo.latitude    as seller_latitude,
        seller_geo.longitude   as seller_longitude,
        customer_geo.latitude  as customer_latitude,
        customer_geo.longitude as customer_longitude,

        shipments.freight_cost_brl,
        shipments.item_price_brl,

        products.product_weight_g,
        products.product_volume_cm3

    from shipments

    left join orders
        on shipments.order_id = orders.order_id

    left join products
        on shipments.product_id = products.product_id

    left join sellers
        on shipments.seller_id = sellers.seller_id

    left join customers
        on orders.customer_id = customers.customer_id

    left join geo as seller_geo
        on sellers.seller_zip_prefix = seller_geo.zip_prefix

    left join geo as customer_geo
        on customers.customer_zip_prefix = customer_geo.zip_prefix

),

measured as (

    select
        *,

        seller_state || ' -> ' || customer_state as lane,

        product_weight_g / 1000.0   as actual_weight_kg,
        product_volume_cm3 / 6000.0 as volumetric_weight_kg,

        greatest(
            product_weight_g / 1000.0,
            product_volume_cm3 / 6000.0
        ) as billable_weight_kg,

        {{ haversine_km(
            'seller_latitude',
            'seller_longitude',
            'customer_latitude',
            'customer_longitude'
        ) }} as distance_km

    from joined

),

final as (

    select
        *,

        distance_km is not null as has_distance,

        round(
            freight_cost_brl / nullif(billable_weight_kg * distance_km, 0),
            6
        ) as cost_per_kg_km,

        date_diff('day', purchased_at, delivered_at)       as days_to_deliver,
        date_diff('day', promised_delivery_at, delivered_at) as days_vs_promise,

        case
            when delivered_at is null then null
            when delivered_at <= promised_delivery_at then true
            else false
        end as delivered_on_time

    from measured

)

select * from final