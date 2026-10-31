-- ==========================================
-- Diamond Sales Database - Schema (SQLite)
-- ==========================================
-- Star schema: one fact table (sales) and three dimension tables
-- (products, channels, stores), built from diamond_sales_clean.csv.

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS channels;
DROP TABLE IF EXISTS stores;

-- Physical and quality characteristics of each diamond
CREATE TABLE products (
    diamond_id     TEXT PRIMARY KEY,
    carat          REAL NOT NULL CHECK (carat > 0),
    cut            TEXT NOT NULL,
    color          TEXT NOT NULL,
    clarity        TEXT NOT NULL,
    depth_pct      REAL,
    table_pct      REAL,
    length_mm      REAL,
    width_mm       REAL,
    height_mm      REAL,
    certification  TEXT,
    appraisal_usd  INTEGER NOT NULL
);

-- Sales channels (Showroom, Boutique, Online, Wholesale)
CREATE TABLE channels (
    channel_id    INTEGER PRIMARY KEY,
    channel_name  TEXT NOT NULL UNIQUE,
    channel_type  TEXT NOT NULL CHECK (channel_type IN ('Physical', 'Digital', 'Trade'))
);

-- Store locations
CREATE TABLE stores (
    store_id        INTEGER PRIMARY KEY,
    store_location  TEXT NOT NULL UNIQUE
);

-- One row per sale
CREATE TABLE sales (
    sale_id                INTEGER PRIMARY KEY,
    diamond_id             TEXT    NOT NULL REFERENCES products (diamond_id),
    channel_id             INTEGER NOT NULL REFERENCES channels (channel_id),
    store_id               INTEGER NOT NULL REFERENCES stores (store_id),
    sale_date              TEXT    NOT NULL,              -- ISO format: YYYY-MM-DD
    price_usd              INTEGER NOT NULL CHECK (price_usd > 0),
    discount_percent       REAL,
    days_on_market         REAL,
    customer_satisfaction  REAL CHECK (customer_satisfaction BETWEEN 0 AND 10)
);

CREATE INDEX idx_sales_date    ON sales (sale_date);
CREATE INDEX idx_sales_channel ON sales (channel_id);
CREATE INDEX idx_sales_store   ON sales (store_id);
