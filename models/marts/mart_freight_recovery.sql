{{ config(materialized = 'table') }}

with shipments as (

    select * from {{ ref('fct_shipments') }}

),

bounds as (

    select max(purchased_at) as last_order_at
    from shipments
    where in_recovery_scope

),

ttm as (

    select shipments.*
    from shipments, bounds
    where shipments.in_recovery_scope
      and shipments.purchased_at > bounds.last_order_at - interval 12 month

),

by_lane_band as (

    select
        lane,
        seller_state,
        customer_state,
        weight_band,

        count(*)                              as shipment_count,
        round(sum(freight_cost_brl), 2)       as freight_brl,
        round(median(distance_km), 1)         as median_distance_km,

        round(sum(greatest(
            freight_cost_brl - median_rate * billable_weight_kg * distance_km, 0
        )), 2) as recoverable_conservative_brl,

        round(sum(excess_spend_brl), 2)       as recoverable_aggressive_brl,

        round(avg(case
            when delivered_on_time is null then null
            when delivered_on_time then 1.0
            else 0.0
        end), 3) as on_time_rate

    from ttm
    group by 1, 2, 3, 4

),

ranked as (

    select
        *,

        round(100.0 * recoverable_conservative_brl / nullif(freight_brl, 0), 1)
            as pct_recoverable_conservative,

        row_number() over (order by recoverable_conservative_brl desc)
            as recovery_rank,

        round(
            100.0
            * sum(recoverable_conservative_brl) over (
                order by recoverable_conservative_brl desc
                rows between unbounded preceding and current row
              )
            / sum(recoverable_conservative_brl) over (),
            1
        ) as cumulative_pct_of_opportunity

    from by_lane_band

)

select * from ranked
order by recovery_rank