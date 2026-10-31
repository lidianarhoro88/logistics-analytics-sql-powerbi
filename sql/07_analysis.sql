/* =====================================================
   Step 7: Business questions
   ===================================================== */
USE logistics_db;
GO

-- Q1. What share of delivered shipments arrive on time? (headline KPI)
SELECT
    COUNT(*)                                   AS delivered_shipments,
    SUM(is_on_time)                            AS on_time,
    CAST(AVG(is_on_time * 1.0) * 100 AS DECIMAL(5,1)) AS on_time_pct
FROM mart.fact_shipments
WHERE is_on_time IS NOT NULL;


-- Q2. Which city has the worst on-time performance?
SELECT
    c.city,
    COUNT(*)                                   AS shipments,
    CAST(AVG(f.is_on_time * 1.0) * 100 AS DECIMAL(5,1)) AS on_time_pct
FROM mart.fact_shipments f
JOIN mart.dim_customer c ON f.customer_id = c.customer_id
WHERE f.is_on_time IS NOT NULL
GROUP BY c.city
ORDER BY on_time_pct;


-- Q3. Rank drivers from worst to best (window function)
SELECT
    d.driver_name,
    COUNT(*)                                   AS deliveries,
    CAST(AVG(f.is_on_time * 1.0) * 100 AS DECIMAL(5,1)) AS on_time_pct,
    RANK() OVER (ORDER BY AVG(f.is_on_time * 1.0)) AS worst_rank
FROM mart.fact_shipments f
JOIN mart.dim_driver d ON f.driver_id = d.driver_id
WHERE f.is_on_time IS NOT NULL
  AND d.driver_id <> 'UNKNOWN'
GROUP BY d.driver_name
HAVING COUNT(*) >= 20
ORDER BY worst_rank;

-- Q4. Revenue, fuel cost and margin by vehicle type
SELECT
    v.vehicle_type,
    COUNT(*)                   AS shipments,
    SUM(f.price)               AS revenue,
    SUM(f.fuel_cost)           AS fuel_cost,
    SUM(f.gross_margin)        AS margin,
    CAST(SUM(f.gross_margin) / SUM(f.price) * 100 AS DECIMAL(5,1)) AS margin_pct
FROM mart.fact_shipments f
JOIN mart.dim_vehicle v ON f.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_type
ORDER BY margin_pct DESC;

-- Q5. Monthly revenue with running total
SELECT
    dt.year_month,
    SUM(f.price)                                        AS monthly_revenue,
    SUM(SUM(f.price)) OVER (ORDER BY dt.year_month)     AS running_total
FROM mart.fact_shipments f
JOIN mart.dim_date dt ON f.ship_date = dt.date_key
GROUP BY dt.year_month
ORDER BY dt.year_month;

-- Q6. Why do shipments fail?
SELECT
    status,
    failure_reason,
    COUNT(*) AS cnt
FROM mart.fact_shipments
WHERE status IN ('Failed', 'Returned', 'Cancelled')
GROUP BY status, failure_reason
ORDER BY status, cnt DESC;
