/* =====================================================
   Step 4: Clean raw.* tables into clean.* tables
   Safe to re-run: every table is dropped and rebuilt.
   ===================================================== */
USE logistics_db;
GO

/* ---------- 4.0 Drop shipments first ----------
   shipments has Foreign Keys pointing to customers/drivers/vehicles,
   so it must be dropped before them (dropping it removes the FKs too). */
DROP TABLE IF EXISTS clean.shipments;
GO

/* ---------- 4.1 Customers ---------- */
DROP TABLE IF EXISTS clean.customers;
GO

WITH dedup AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
    FROM raw.raw_customers
)
SELECT
    TRIM(customer_id)                       AS customer_id,
    TRIM(customer_name)                     AS customer_name,
    CASE 
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) IN ('ISTANBUL', 'IST') THEN 'Istanbul'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'ANKARA'  THEN 'Ankara'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'IZMIR'   THEN 'Izmir'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'BURSA'   THEN 'Bursa'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'ANTALYA' THEN 'Antalya'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'KOCAELI' THEN 'Kocaeli'
        ELSE NULL
    END                                     AS city,
    NULLIF(RIGHT(REPLACE(REPLACE(REPLACE(phone, ' ', ''), '-', ''), '+', ''), 10), '') AS phone,
    COALESCE(
        TRY_CONVERT(DATE, signup_date, 23),   -- 2023-11-03
        TRY_CONVERT(DATE, signup_date, 103),  -- 25/07/2022
        TRY_CONVERT(DATE, signup_date, 104),  -- 25.07.2022
        TRY_CONVERT(DATE, signup_date, 112)   -- 20220725
    )                                       AS signup_date
INTO clean.customers
FROM dedup
WHERE rn = 1;
GO

/* ---------- 4.2 Drivers ---------- */
DROP TABLE IF EXISTS clean.drivers;
GO

WITH dedup AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY driver_id ORDER BY driver_id) AS rn
    FROM raw.raw_drivers
)
SELECT
    TRIM(driver_id)    AS driver_id,
    TRIM(driver_name)  AS driver_name,
    COALESCE(
        TRY_CONVERT(DATE, hire_date, 23),
        TRY_CONVERT(DATE, hire_date, 103),
        TRY_CONVERT(DATE, hire_date, 104),
        TRY_CONVERT(DATE, hire_date, 112)
    )                  AS hire_date,
    CASE 
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) IN ('ISTANBUL', 'IST') THEN 'Istanbul'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'ANKARA'  THEN 'Ankara'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'IZMIR'   THEN 'Izmir'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'BURSA'   THEN 'Bursa'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'ANTALYA' THEN 'Antalya'
        WHEN UPPER(REPLACE(TRIM(city), N'İ', N'I')) = 'KOCAELI' THEN 'Kocaeli'
        ELSE NULL
    END                AS city
INTO clean.drivers
FROM dedup
WHERE rn = 1;
GO

/* ---------- 4.3 Vehicles ---------- */
DROP TABLE IF EXISTS clean.vehicles;
GO

SELECT
    TRIM(vehicle_id) AS vehicle_id,
    CASE UPPER(REPLACE(TRIM(vehicle_type), ' ', ''))
        WHEN 'MOTORCYCLE' THEN 'Motorcycle'
        WHEN 'VAN'        THEN 'Van'
        WHEN 'LIGHTTRUCK' THEN 'Light Truck'
        WHEN 'HEAVYTRUCK' THEN 'Heavy Truck'
        ELSE NULL
    END AS vehicle_type,
    TRY_CAST(NULLIF(TRIM(REPLACE(capacity_kg, 'kg', '')), '') AS INT)   AS capacity_kg,
    TRY_CAST(REPLACE(TRIM(fuel_cost_per_km), ',', '.') AS DECIMAL(6,2)) AS fuel_cost_per_km
INTO clean.vehicles
FROM raw.raw_vehicles;
GO

/* ---------- Status check (expected: 200, 40, 30) ---------- */
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM clean.customers
UNION ALL SELECT 'drivers',  COUNT(*) FROM clean.drivers
UNION ALL SELECT 'vehicles', COUNT(*) FROM clean.vehicles;

SELECT COUNT(*) AS vehicles_missing_capacity
FROM clean.vehicles
WHERE capacity_kg IS NULL;
/* ---------- 4.4 Fill missing capacity from same vehicle type ---------- */
UPDATE v
SET v.capacity_kg = t.typical_capacity
FROM clean.vehicles v
JOIN (
    SELECT vehicle_type, MAX(capacity_kg) AS typical_capacity
    FROM clean.vehicles
    WHERE capacity_kg IS NOT NULL
    GROUP BY vehicle_type
) t ON v.vehicle_type = t.vehicle_type
WHERE v.capacity_kg IS NULL;
GO
/* ---------- 4.5 Shipments ---------- */
DROP TABLE IF EXISTS clean.shipments;
GO

WITH dedup AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY shipment_id ORDER BY shipment_id) AS rn
    FROM raw.raw_shipments
)
SELECT
    TRIM(shipment_id)                 AS shipment_id,
    NULLIF(TRIM(customer_id), '')     AS customer_id,
    NULLIF(TRIM(driver_id), '')       AS driver_id,
    NULLIF(TRIM(vehicle_id), '')      AS vehicle_id,

    COALESCE(TRY_CONVERT(DATE, ship_date, 23), TRY_CONVERT(DATE, ship_date, 103),
             TRY_CONVERT(DATE, ship_date, 104), TRY_CONVERT(DATE, ship_date, 112))           AS ship_date,
    COALESCE(TRY_CONVERT(DATE, promised_date, 23), TRY_CONVERT(DATE, promised_date, 103),
             TRY_CONVERT(DATE, promised_date, 104), TRY_CONVERT(DATE, promised_date, 112))   AS promised_date,
    COALESCE(TRY_CONVERT(DATE, delivered_date, 23), TRY_CONVERT(DATE, delivered_date, 103),
             TRY_CONVERT(DATE, delivered_date, 104), TRY_CONVERT(DATE, delivered_date, 112)) AS delivered_date,

    ABS(TRY_CAST(NULLIF(TRIM(REPLACE(distance_km, 'km', '')), '') AS DECIMAL(8,1)))  AS distance_km,
    NULLIF(TRY_CAST(REPLACE(TRIM(price), ',', '.') AS DECIMAL(10,2)), 0)            AS price,

    CASE UPPER(TRIM(status))
        WHEN 'DELIVERED'  THEN 'Delivered'
        WHEN 'FAILED'     THEN 'Failed'
        WHEN 'RETURNED'   THEN 'Returned'
        WHEN 'IN TRANSIT' THEN 'In Transit'
        WHEN 'CANCELLED'  THEN 'Cancelled'
        ELSE NULL
    END                               AS status,
    NULLIF(TRIM(failure_reason), '')  AS failure_reason
INTO clean.shipments
FROM dedup
WHERE rn = 1;
GO

SELECT COUNT(*) AS total_rows FROM clean.shipments;   -- expected: 2000
SELECT status, COUNT(*) AS cnt FROM clean.shipments GROUP BY status;