/* =====================================================
   Step 3: Data profiling - find problems before fixing them
   ===================================================== */
USE logistics_db;
GO

-- 1. Look at a sample of raw shipments (mixed date formats, text in numbers)
SELECT TOP 20 *
FROM raw.raw_shipments;

-- 2. City spellings (case, Turkish dotted I, abbreviations, spaces, blanks)
SELECT city, COUNT(*) AS customer_count
FROM raw.raw_customers
GROUP BY city
ORDER BY city;

-- 3. Status spellings
SELECT status, COUNT(*) AS shipment_count
FROM raw.raw_shipments
GROUP BY status
ORDER BY shipment_count DESC;

-- 4. Duplicate business keys
SELECT shipment_id, COUNT(*) AS copies
FROM raw.raw_shipments
GROUP BY shipment_id
HAVING COUNT(*) > 1;

-- 5. Numbers stored with text or comma decimals
SELECT TOP 20 shipment_id, distance_km, price
FROM raw.raw_shipments
WHERE TRY_CAST(distance_km AS DECIMAL(8,1)) IS NULL
   OR TRY_CAST(price AS DECIMAL(10,2)) IS NULL;
