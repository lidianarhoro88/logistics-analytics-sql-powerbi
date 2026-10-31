/* =====================================================
   Step 6: Star schema (mart layer) for Power BI
   ===================================================== */
USE logistics_db;
GO

IF SCHEMA_ID('mart') IS NULL EXEC('CREATE SCHEMA mart');
GO

/* ========== 6.1 Date dimension ========== */
DROP TABLE IF EXISTS mart.dim_date;
GO

WITH dates AS (
    SELECT CAST('2024-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM dates WHERE d < '2026-01-31'
)
SELECT
    d                                AS date_key,
    YEAR(d)                          AS [year],
    DATEPART(QUARTER, d)             AS [quarter],
    MONTH(d)                         AS month_number,
    DATENAME(MONTH, d)               AS month_name,
    FORMAT(d, 'yyyy-MM')             AS year_month,
    DATENAME(WEEKDAY, d)             AS day_name,
    CASE WHEN DATEPART(WEEKDAY, d) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
INTO mart.dim_date
FROM dates
OPTION (MAXRECURSION 0);
GO

ALTER TABLE mart.dim_date ALTER COLUMN date_key DATE NOT NULL;
GO
ALTER TABLE mart.dim_date ADD CONSTRAINT PK_dim_date PRIMARY KEY (date_key);
GO

/* ========== 6.2 Dimension views ========== */
CREATE OR ALTER VIEW mart.dim_customer AS
SELECT customer_id, customer_name, ISNULL(city, 'Unknown') AS city, signup_date
FROM clean.customers;
GO

CREATE OR ALTER VIEW mart.dim_driver AS
SELECT driver_id, driver_name, ISNULL(city, 'Unknown') AS city, hire_date
FROM clean.drivers;
GO

CREATE OR ALTER VIEW mart.dim_vehicle AS
SELECT vehicle_id, vehicle_type, capacity_kg, fuel_cost_per_km
FROM clean.vehicles;
GO

/* ========== 6.3 Fact view ========== */
CREATE OR ALTER VIEW mart.fact_shipments AS
SELECT
    s.shipment_id,
    s.customer_id,
    s.driver_id,
    s.vehicle_id,
    s.ship_date,
    s.promised_date,
    s.delivered_date,
    s.status,
    s.failure_reason,
    s.distance_km,
    s.price,
    DATEDIFF(DAY, s.ship_date, s.delivered_date)            AS delivery_days,
    CASE 
        WHEN s.status = 'Delivered' AND s.delivered_date IS NOT NULL
        THEN CASE WHEN s.delivered_date <= s.promised_date THEN 1 ELSE 0 END
    END                                                     AS is_on_time,
    CAST(s.distance_km * v.fuel_cost_per_km AS DECIMAL(10,2))            AS fuel_cost,
    CAST(s.price - s.distance_km * v.fuel_cost_per_km AS DECIMAL(10,2))  AS gross_margin
FROM clean.shipments s
LEFT JOIN clean.vehicles v ON s.vehicle_id = v.vehicle_id;
GO

/* ========== 6.4 Quick test ========== */
SELECT TOP 10 * FROM mart.fact_shipments;
SELECT COUNT(*) AS days_in_calendar FROM mart.dim_date;
