"""Load the raw Olist CSV files into a DuckDB database.

Run from the project root:
    python scripts/load_raw.py
"""

import duckdb
import pathlib

RAW_DIR = pathlib.Path("data/raw")
DB_PATH = "data/freight.duckdb"

TABLES = {
    "orders":      "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "products":    "olist_products_dataset.csv",
    "sellers":     "olist_sellers_dataset.csv",
    "customers":   "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
}

con = duckdb.connect(DB_PATH)
con.execute("CREATE SCHEMA IF NOT EXISTS raw")

for table_name, file_name in TABLES.items():
    csv_path = RAW_DIR / file_name

    if not csv_path.exists():
        raise FileNotFoundError(f"Missing file: {csv_path}")

    con.execute(f"""
        CREATE OR REPLACE TABLE raw.{table_name} AS
        SELECT * FROM read_csv_auto('{csv_path.as_posix()}', header = true)
    """)

    row_count = con.execute(f"SELECT count(*) FROM raw.{table_name}").fetchone()[0]
    print(f"  {table_name:<12} {row_count:>9,} rows")

print("\nDone.")
con.close()