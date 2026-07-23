with source as (

    select * from {{ source('olist', 'products') }}

),

renamed as (

    select
        product_id,
        product_category_name              as product_category,

        cast(product_weight_g as integer)  as product_weight_g,
        cast(product_length_cm as integer) as product_length_cm,
        cast(product_height_cm as integer) as product_height_cm,
        cast(product_width_cm as integer)  as product_width_cm,

        cast(product_length_cm as integer)
            * cast(product_height_cm as integer)
            * cast(product_width_cm as integer) as product_volume_cm3

    from source

)

select * from renamed