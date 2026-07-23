with source as (

    select * from {{ source('olist', 'geolocation') }}

),

cleaned as (

    select
        lpad(cast(geolocation_zip_code_prefix as varchar), 5, '0') as zip_prefix,
        cast(geolocation_lat as double)                            as latitude,
        cast(geolocation_lng as double)                            as longitude

    from source

    -- Drop coordinates that fall outside Brazil's borders. A handful of rows
    -- carry bad lat/lng values that would badly distort distance calculations.
    where geolocation_lat between -34.0 and 5.3
      and geolocation_lng between -74.0 and -34.8

),

centroids as (

    select
        zip_prefix,
        avg(latitude)  as latitude,
        avg(longitude) as longitude,
        count(*)       as point_count

    from cleaned
    group by zip_prefix

)

select * from centroids