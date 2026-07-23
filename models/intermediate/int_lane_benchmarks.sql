{{ config(materialized = 'table') }}

with shipments as (

    select * from {{ ref('int_shipments_enriched') }}

),

eligible as (

    select
        lane,
        seller_state,
        customer_state,
        {{ weight_band('billable_weight_kg') }} as weight_band,
        billable_weight_kg,
        distance_km,
        freight_cost_brl,
        cost_per_kg_km

    from shipments

    where has_distance
      and distance_km > 0
      and billable_weight_kg > 0
      and cost_per_kg_km is not null
      and order_status not in ('canceled', 'unavailable')

),

benchmarks as (

    select
        lane,
        seller_state,
        customer_state,
        weight_band,

        count(*)                                   as shipment_count,
        sum(freight_cost_brl)                      as total_freight_brl,
        round(median(distance_km), 1)              as median_distance_km,

        round(quantile_cont(cost_per_kg_km, 0.25), 6) as benchmark_rate,
        round(median(cost_per_kg_km), 6)              as median_rate,
        round(quantile_cont(cost_per_kg_km, 0.75), 6) as p75_rate

    from eligible

    group by lane, seller_state, customer_state, weight_band

),

final as (

    select
        *,
        shipment_count >= 30 as is_benchmarkable

    from benchmarks

)

select * from final