/* =====================================================
   Step 2: Load raw CSV files into raw.* tables
   ===================================================== */
USE logistics_db;
GO

-- Empty the tables first, so re-running this script never duplicates data
TRUNCATE TABLE raw.raw_customers;
TRUNCATE TABLE raw.raw_drivers;
TRUNCATE TABLE raw.raw_vehicles;
TRUNCATE TABLE raw.raw_shipments;
GO

BULK INSERT raw.raw_customers
FROM 'C:\logistics_data\customers.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001');

BULK INSERT raw.raw_drivers
FROM 'C:\logistics_data\drivers.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001');

BULK INSERT raw.raw_vehicles
FROM 'C:\logistics_data\vehicles.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001');

BULK INSERT raw.raw_shipments
FROM 'C:\logistics_data\shipments.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001');
GO

-- Check row counts (expected: 208, 42, 30, 2025)
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM raw.raw_customers
UNION ALL SELECT 'drivers',   COUNT(*) FROM raw.raw_drivers
UNION ALL SELECT 'vehicles',  COUNT(*) FROM raw.raw_vehicles
UNION ALL SELECT 'shipments', COUNT(*) FROM raw.raw_shipments;
