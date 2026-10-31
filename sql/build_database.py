# ==========================================
# Build the SQLite database from the cleaned CSV
# ==========================================
# Usage (from the repository root):
#   python sql/build_database.py

import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / 'diamond_sales_clean.csv'
DB_PATH = ROOT / 'sql' / 'diamonds.db'
SCHEMA_PATH = ROOT / 'sql' / 'schema.sql'

CHANNEL_TYPES = {
    'Showroom': 'Physical',
    'Boutique': 'Physical',
    'Online': 'Digital',
    'Wholesale': 'Trade'
}

df = pd.read_csv(CSV_PATH)

# ==========================================
# Dimension tables
# ==========================================

products = df[[
    'DiamondID', 'Carat', 'Cut', 'Color', 'Clarity',
    'DepthPct', 'TablePct', 'LengthMm', 'WidthMm', 'HeightMm',
    'Certification', 'AppraisalUSD'
]].rename(columns={
    'DiamondID': 'diamond_id',
    'Carat': 'carat',
    'Cut': 'cut',
    'Color': 'color',
    'Clarity': 'clarity',
    'DepthPct': 'depth_pct',
    'TablePct': 'table_pct',
    'LengthMm': 'length_mm',
    'WidthMm': 'width_mm',
    'HeightMm': 'height_mm',
    'Certification': 'certification',
    'AppraisalUSD': 'appraisal_usd'
})

channels = pd.DataFrame({
    'channel_name': sorted(df['SalesChannel'].unique())
})
channels['channel_id'] = range(1, len(channels) + 1)
channels['channel_type'] = channels['channel_name'].map(CHANNEL_TYPES)

stores = pd.DataFrame({
    'store_location': sorted(df['StoreLocation'].unique())
})
stores['store_id'] = range(1, len(stores) + 1)

# ==========================================
# Fact table
# ==========================================

sales = (
    df.merge(channels, left_on='SalesChannel', right_on='channel_name')
      .merge(stores, left_on='StoreLocation', right_on='store_location')
      .sort_values(['SaleDate', 'DiamondID'])
      .reset_index(drop=True)
)
sales['sale_id'] = range(1, len(sales) + 1)

sales = sales[[
    'sale_id', 'DiamondID', 'channel_id', 'store_id', 'SaleDate',
    'PriceUSD', 'DiscountPercent', 'DaysOnMarket', 'CustomerSatisfaction'
]].rename(columns={
    'DiamondID': 'diamond_id',
    'SaleDate': 'sale_date',
    'PriceUSD': 'price_usd',
    'DiscountPercent': 'discount_percent',
    'DaysOnMarket': 'days_on_market',
    'CustomerSatisfaction': 'customer_satisfaction'
})

# ==========================================
# Load into SQLite
# ==========================================

DB_PATH.unlink(missing_ok=True)

with sqlite3.connect(DB_PATH) as conn:
    conn.execute('PRAGMA foreign_keys = ON')
    conn.executescript(SCHEMA_PATH.read_text(encoding='utf-8'))

    products.to_sql('products', conn, if_exists='append', index=False)
    channels[['channel_id', 'channel_name', 'channel_type']].to_sql('channels', conn, if_exists='append', index=False)
    stores[['store_id', 'store_location']].to_sql('stores', conn, if_exists='append', index=False)
    sales.to_sql('sales', conn, if_exists='append', index=False)

    for table in ['products', 'channels', 'stores', 'sales']:
        count = conn.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
        print(f'{table:<10} {count:>6,} rows')

print(f'\nDatabase created: {DB_PATH.relative_to(ROOT)}')
