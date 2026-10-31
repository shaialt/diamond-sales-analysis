-- ==========================================
-- Diamond Sales Analysis - Business Queries (SQLite)
-- ==========================================
-- Database: sql/diamonds.db (built by sql/build_database.py)
-- Each query starts with a "-- Q<number> [name]:" header so it can be run
-- individually by sql/run_queries.py.


-- Q1 [yoy_growth]: How did sales volume and revenue grow year over year?
-- Techniques: CTE, LAG() window function
WITH yearly AS (
    SELECT
        CAST(strftime('%Y', sale_date) AS INTEGER) AS sale_year,
        COUNT(*)                                   AS diamonds_sold,
        SUM(price_usd)                             AS revenue_usd,
        ROUND(AVG(price_usd), 2)                   AS avg_price_usd
    FROM sales
    GROUP BY sale_year
)
SELECT
    sale_year,
    diamonds_sold,
    revenue_usd,
    avg_price_usd,
    ROUND(
        100.0 * (diamonds_sold - LAG(diamonds_sold) OVER (ORDER BY sale_year))
        / LAG(diamonds_sold) OVER (ORDER BY sale_year), 2
    ) AS volume_growth_pct,
    ROUND(
        100.0 * (revenue_usd - LAG(revenue_usd) OVER (ORDER BY sale_year))
        / LAG(revenue_usd) OVER (ORDER BY sale_year), 2
    ) AS revenue_growth_pct
FROM yearly
ORDER BY sale_year;


-- Q2 [monthly_running_total]: What is the monthly revenue trend, year-to-date total and 3-month moving average?
-- Techniques: CTE, SUM() OVER (PARTITION BY ... ORDER BY ...), AVG() OVER (ROWS BETWEEN ...)
WITH monthly AS (
    SELECT
        strftime('%Y', sale_date)    AS sale_year,
        strftime('%Y-%m', sale_date) AS sale_month,
        COUNT(*)                     AS diamonds_sold,
        SUM(price_usd)               AS revenue_usd
    FROM sales
    GROUP BY sale_year, sale_month
)
SELECT
    sale_month,
    diamonds_sold,
    revenue_usd,
    SUM(revenue_usd) OVER (
        PARTITION BY sale_year
        ORDER BY sale_month
    ) AS ytd_revenue_usd,
    ROUND(AVG(revenue_usd) OVER (
        ORDER BY sale_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0) AS moving_avg_3m_usd
FROM monthly
ORDER BY sale_month;


-- Q3 [channel_performance]: How does each sales channel perform on price, discount, satisfaction and speed?
-- Techniques: JOIN, GROUP BY, SUM() OVER () for share of total
SELECT
    c.channel_name,
    c.channel_type,
    COUNT(*)                                            AS diamonds_sold,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS share_of_sales_pct,
    ROUND(AVG(s.price_usd), 2)                          AS avg_price_usd,
    ROUND(AVG(s.discount_percent), 2)                   AS avg_discount_pct,
    ROUND(AVG(s.customer_satisfaction), 2)              AS avg_satisfaction,
    ROUND(AVG(s.days_on_market), 1)                     AS avg_days_on_market
FROM sales AS s
JOIN channels AS c ON c.channel_id = s.channel_id
GROUP BY c.channel_name, c.channel_type
ORDER BY avg_price_usd DESC;


-- Q4 [top_diamonds_per_channel]: What are the three most expensive diamonds sold in each channel?
-- Techniques: CTE, ROW_NUMBER() OVER (PARTITION BY ...), three-table JOIN
WITH ranked_sales AS (
    SELECT
        c.channel_name,
        p.diamond_id,
        p.carat,
        p.cut,
        p.color,
        p.clarity,
        s.price_usd,
        ROW_NUMBER() OVER (
            PARTITION BY c.channel_name
            ORDER BY s.price_usd DESC, p.diamond_id
        ) AS price_rank
    FROM sales AS s
    JOIN products AS p ON p.diamond_id = s.diamond_id
    JOIN channels AS c ON c.channel_id = s.channel_id
)
SELECT *
FROM ranked_sales
WHERE price_rank <= 3
ORDER BY channel_name, price_rank;


-- Q5 [top_months_per_year]: Which months bring the most revenue in each year?
-- Techniques: CTE, RANK() OVER (PARTITION BY ...)
WITH monthly AS (
    SELECT
        strftime('%Y', sale_date) AS sale_year,
        strftime('%m', sale_date) AS sale_month,
        COUNT(*)                  AS diamonds_sold,
        SUM(price_usd)            AS revenue_usd
    FROM sales
    GROUP BY sale_year, sale_month
),
ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY sale_year
            ORDER BY revenue_usd DESC
        ) AS revenue_rank
    FROM monthly
)
SELECT sale_year, revenue_rank, sale_month, diamonds_sold, revenue_usd
FROM ranked
WHERE revenue_rank <= 3
ORDER BY sale_year, revenue_rank;


-- Q6 [price_segments]: How are sales and revenue distributed across price segments?
-- Techniques: CASE WHEN segmentation, CTE, SUM() OVER () for shares
WITH segmented AS (
    SELECT
        CASE
            WHEN s.price_usd < 2000  THEN '1. Entry (< $2K)'
            WHEN s.price_usd < 5000  THEN '2. Mid ($2K-$5K)'
            WHEN s.price_usd < 10000 THEN '3. High ($5K-$10K)'
            ELSE '4. Luxury ($10K+)'
        END AS price_segment,
        s.price_usd,
        p.carat
    FROM sales AS s
    JOIN products AS p ON p.diamond_id = s.diamond_id
)
SELECT
    price_segment,
    COUNT(*)                                                   AS diamonds_sold,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)         AS share_of_sales_pct,
    SUM(price_usd)                                             AS revenue_usd,
    ROUND(100.0 * SUM(price_usd) / SUM(SUM(price_usd)) OVER (), 2) AS share_of_revenue_pct,
    ROUND(AVG(carat), 2)                                       AS avg_carat
FROM segmented
GROUP BY price_segment
ORDER BY price_segment;


-- Q7 [carat_confounding]: Are Premium cuts really cheaper than Standard cuts, or is carat weight the hidden factor?
-- Techniques: CTE, CASE WHEN grouping, conditional aggregation (pivot), UNION ALL
WITH grouped AS (
    SELECT
        CASE WHEN p.cut IN ('Ideal', 'Premium') THEN 'Premium' ELSE 'Standard' END AS quality_group,
        CASE
            WHEN p.carat <= 0.5 THEN '1. 0-0.5 ct'
            WHEN p.carat <= 1.0 THEN '2. 0.5-1 ct'
            WHEN p.carat <= 1.5 THEN '3. 1-1.5 ct'
            WHEN p.carat <= 2.0 THEN '4. 1.5-2 ct'
            ELSE '5. 2+ ct'
        END AS carat_group,
        p.carat,
        s.price_usd
    FROM sales AS s
    JOIN products AS p ON p.diamond_id = s.diamond_id
),
comparison AS (
    SELECT '0. All diamonds' AS carat_group, quality_group, carat, price_usd FROM grouped
    UNION ALL
    SELECT carat_group, quality_group, carat, price_usd FROM grouped
)
SELECT
    carat_group,
    SUM(CASE WHEN quality_group = 'Premium'  THEN 1 ELSE 0 END)                 AS premium_count,
    SUM(CASE WHEN quality_group = 'Standard' THEN 1 ELSE 0 END)                 AS standard_count,
    ROUND(AVG(CASE WHEN quality_group = 'Premium'  THEN carat END), 2)          AS premium_avg_carat,
    ROUND(AVG(CASE WHEN quality_group = 'Standard' THEN carat END), 2)          AS standard_avg_carat,
    ROUND(AVG(CASE WHEN quality_group = 'Premium'  THEN price_usd END), 2)      AS premium_avg_price,
    ROUND(AVG(CASE WHEN quality_group = 'Standard' THEN price_usd END), 2)      AS standard_avg_price,
    ROUND(
        AVG(CASE WHEN quality_group = 'Premium'  THEN price_usd END)
      - AVG(CASE WHEN quality_group = 'Standard' THEN price_usd END), 2
    ) AS premium_minus_standard
FROM comparison
GROUP BY carat_group
ORDER BY carat_group;


-- Q8 [major_markets]: Which store locations are major markets (700+ sales), and how do they compare?
-- Techniques: JOIN, GROUP BY with HAVING
SELECT
    st.store_location,
    COUNT(*)                               AS diamonds_sold,
    SUM(s.price_usd)                       AS revenue_usd,
    ROUND(AVG(s.price_usd), 2)             AS avg_price_usd,
    ROUND(AVG(s.customer_satisfaction), 2) AS avg_satisfaction
FROM sales AS s
JOIN stores AS st ON st.store_id = s.store_id
WHERE st.store_location <> 'Unknown'
GROUP BY st.store_location
HAVING COUNT(*) >= 700
ORDER BY revenue_usd DESC;


-- Q9 [clarity_price_per_carat]: Which clarity grades command a higher price per carat than the overall average?
-- Techniques: GROUP BY with HAVING and a scalar subquery
SELECT
    p.clarity,
    COUNT(*)                              AS diamonds_sold,
    ROUND(AVG(p.carat), 2)                AS avg_carat,
    ROUND(AVG(s.price_usd / p.carat), 2)  AS avg_price_per_carat
FROM sales AS s
JOIN products AS p ON p.diamond_id = s.diamond_id
GROUP BY p.clarity
HAVING AVG(s.price_usd / p.carat) > (
    SELECT AVG(s2.price_usd / p2.carat)
    FROM sales AS s2
    JOIN products AS p2 ON p2.diamond_id = s2.diamond_id
)
ORDER BY avg_price_per_carat DESC;


-- Q10 [below_appraisal_by_certification]: How often are diamonds sold below their appraised value, by certification?
-- Techniques: CASE WHEN inside aggregate functions, JOIN
SELECT
    p.certification,
    COUNT(*) AS diamonds_sold,
    ROUND(
        100.0 * SUM(CASE WHEN s.price_usd < p.appraisal_usd THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS sold_below_appraisal_pct,
    ROUND(AVG(p.appraisal_usd - s.price_usd), 2) AS avg_gap_to_appraisal_usd,
    ROUND(AVG(s.discount_percent), 2)            AS avg_discount_pct
FROM sales AS s
JOIN products AS p ON p.diamond_id = s.diamond_id
GROUP BY p.certification
ORDER BY sold_below_appraisal_pct DESC;
