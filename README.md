# Freight Cost Recovery

Lane-level freight cost analysis on 100,000 marketplace orders.
Built with dbt, DuckDB, and SQL.

---

## The finding

Over the twelve months ending September 2018, this marketplace spent
**R$1.55M (~US$424K)** shipping 81,341 orders.

**R$337K–584K of that (~US$92K–160K, or 22–38%) is recoverable** by bringing
overpriced lanes down to rates already being achieved on those same lanes.

The range is two scenarios, not an error bar:

| Scenario | Basis | Recoverable |
|---|---|---|
| Conservative | Every shipment brought to its lane's **median** rate | R$337K (~$92K) |
| Aggressive | Every shipment brought to its lane's **25th percentile** rate | R$584K (~$160K) |

*Currency converted at R$3.65 = US$1, the 2018 average rate.*

---

## What to do about it

The opportunity is concentrated. **Twelve lane–weight combinations hold 47% of
the total recoverable spend**, and all twelve originate in São Paulo. They split
into three groups, and the right action differs for each.

### 1. São Paulo intra-state — renegotiate now

| Rank | Lane | Weight band | Recoverable | Overspend | On-time |
|---|---|---|---|---|---|
| 1 | SP → SP | 0–1 kg | R$34,393 | 26.4% | 93.9% |
| 2 | SP → SP | 3–10 kg | R$26,884 | 29.3% | 92.9% |
| 3 | SP → SP | 1–3 kg | R$24,708 | 27.0% | 93.7% |
| 4 | SP → SP | 10–30 kg | R$16,540 | 31.4% | 90.4% |

**R$102,525 — 30% of the entire annual opportunity from one origin-destination
pair.** Costs run 26–31% above the lane median while delivery performance holds
at 90–94%. High price, strong service, no operational risk in cutting. This is
the cleanest case on the board.

### 2. São Paulo → Minas Gerais — same play, smaller

Ranks 6, 8, 9 and 11. Overspend of 18–27% at 92–93% on-time. Structurally
identical to SP → SP with roughly a third of the volume.

### 3. São Paulo → Rio de Janeiro — do not lead with a rate cut

Ranks 5, 7, 10 and 12 carry comparable overspend but run **79–84% on-time,
ten to fifteen points below every other lane in the top twelve**. These lanes
are expensive *and* underperforming. Cutting rates here would mean paying less
for service that is already failing in the country's second-largest market.

The recommendation is a carrier performance review first, rate action second.

---

## Why the money sits in short hauls

Cost per kilogram-kilometre falls sharply as distance rises, because fixed
pickup and delivery costs get spread over more kilometres:

| Lane | Median distance | Benchmark rate | Median rate | Gap |
|---|---|---|---|---|
| SP → SP (0–1 kg) | 86 km | 0.106 | 0.258 | 2.4× |
| SP → RJ (0–1 kg) | 374 km | 0.054 | 0.077 | 1.4× |

Short-haul rates are both higher and far more variable. That variance is the
opportunity, and it is why benchmarks are computed **within** each lane and
weight band and never compared across them.

---

## How it works


| Model | Grain | Purpose |
|---|---|---|
| `stg_*` | source table | Type casting, renaming, cleaning |
| `int_shipments_enriched` | one shipment | Six-way join, distance, billable weight |
| `int_lane_benchmarks` | lane × weight band | Benchmark rates and sample sizes |
| `fct_shipments` | one shipment | Actual vs. benchmark cost per shipment |
| `mart_freight_recovery` | lane × weight band | Ranked opportunity with service quality |

**61 data tests** cover uniqueness, grain, foreign keys, value ranges, and
format assertions. Six known source data gaps run as documented warnings rather
than silent exclusions.

---

## Method

**Cost per kilogram-kilometre, not raw freight cost.** A heavy package going
2,000 km should cost more. Normalising by weight and distance is what makes two
shipments comparable.

**Billable weight, not actual weight.** Freight is priced on the greater of
actual weight and volumetric weight (volume ÷ 6000). A pillow costs more to ship
than it weighs.

**Benchmark at the 25th percentile, not the average.** An average is dragged
upward by the overpayments being measured. The p25 says a quarter of shipments
on this lane already achieve this rate, so it is demonstrably attainable.

**Excess is floored at zero per shipment.** Shipments already beating their
benchmark contribute nothing rather than netting off the overpayments. This
measures recoverable overspend, not net variance.

**Minimum 30 shipments per lane–band.** Smaller samples are computed, flagged,
and excluded from recommendations rather than deleted. The 258 qualifying
lane–bands cover 95% of all shipments.

**Trailing twelve months, computed from the data.** Volume nearly doubled
year over year, so a full-period average would understate the current run rate.
The window moves automatically as new data arrives.

---

## Limitations

**Freight charges are not pure linehaul cost.** The source field is the shipping
charge shown to the customer, which bundles handling, packaging, and marketplace
margin. Some measured variance was never carrier cost.

**Distance is great-circle, not road.** Suitable for comparing lanes against
each other, not for estimating actual truck kilometres.

**Locations are postal-prefix centroids.** Coordinates are averaged per prefix,
placing every address at the centre of its area. Immaterial across hauls of
hundreds of kilometres.

**555 shipments (0.5%) have no distance** because their postal prefix has no
coordinates on record. Excluded and reported, not silently dropped.

**No carrier identifier exists in this dataset**, so the analysis is built at
lane level. Freight recovery is negotiated by lane in any case.

---

## Run it

Requires Python 3.12+.

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1        # Windows
source .venv/bin/activate         # macOS / Linux
pip install -r requirements.txt
dbt deps
python scripts/load_raw.py
dbt build
```

Runs on DuckDB locally with no credentials. A Snowflake target is included in
`profiles.yml.example`.

---

## Data

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
— 100,000 anonymised orders, 2016–2018. Download to `data/raw/`.