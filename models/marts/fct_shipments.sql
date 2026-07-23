{{ config(materialized = 'table') }}

with shipments as (

    select * from {{ ref('int_shipments_enriched') }}

),

benchmarks as (

    select * from {{ ref('int_lane_benchmarks') }}

),

banded as (

    select
        *,
        {{ weight_band('billable_weight_kg') }} as weight_band

    from shipments

),

joined as (

    select
        banded.*,

        benchmarks.benchmark_rate,
        benchmarks.median_rate,
        benchmarks.p75_rate,
        benchmarks.shipment_count as lane_band_shipment_count,
        benchmarks.is_benchmarkable

    from banded

    left join benchmarks
        on  banded.lane        = benchmarks.lane
        and banded.weight_band = benchmarks.weight_band

),

costed as (

    select
        *,
        round(benchmark_rate * billable_weight_kg * distance_km, 2) as benchmark_cost_brl

    from joined

),

final as (

    select
        *,

        round(greatest(freight_cost_brl - benchmark_cost_brl, 0), 2) as excess_spend_brl,

        case
            when coalesce(is_benchmarkable, false)
             and has_distance
             and distance_km > 0
             and billable_weight_kg > 0
             and order_status not in ('canceled', 'unavailable')
            then true
            else false
        end as in_recovery_scope

    from costed

)

select * from final