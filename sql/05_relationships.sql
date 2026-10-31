/* =====================================================
   Step 5: Referential integrity, Unknown members, PKs and FKs
   Run after 04_cleaning.sql (which rebuilds clean.*)
   ===================================================== */
USE logistics_db;
GO

/* ========== 5.0 Integrity checks (anti-joins) ========== */
-- 1. Shipments pointing to customers that do not exist
SELECT s.shipment_id, s.customer_id
FROM clean.shipments s
LEFT JOIN clean.customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 2. Shipments pointing to drivers that do not exist
SELECT s.shipment_id, s.driver_id
FROM clean.shipments s
LEFT JOIN clean.drivers d ON s.driver_id = d.driver_id
WHERE s.driver_id IS NOT NULL
  AND d.driver_id IS NULL;

-- 3. Shipments with no driver at all
SELECT COUNT(*) AS shipments_without_driver
FROM clean.shipments
WHERE driver_id IS NULL;

-- 4. Delivered before shipped (logically impossible)
SELECT shipment_id, ship_date, delivered_date
FROM clean.shipments
WHERE delivered_date < ship_date;
GO

/* ========== 5.1 Unknown members ========== */
IF NOT EXISTS (SELECT 1 FROM clean.customers WHERE customer_id = 'UNKNOWN')
    INSERT INTO clean.customers (customer_id, customer_name, city)
    VALUES ('UNKNOWN', 'Unknown Customer', NULL);

IF NOT EXISTS (SELECT 1 FROM clean.drivers WHERE driver_id = 'UNKNOWN')
    INSERT INTO clean.drivers (driver_id, driver_name, city)
    VALUES ('UNKNOWN', 'Unknown Driver', NULL);
GO

/* ========== 5.2 Fix orphans & bad dates ========== */
-- Orphan customers -> UNKNOWN member
UPDATE s SET s.customer_id = 'UNKNOWN'
FROM clean.shipments s
LEFT JOIN clean.customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orphan or missing drivers -> UNKNOWN member
UPDATE s SET s.driver_id = 'UNKNOWN'
FROM clean.shipments s
LEFT JOIN clean.drivers d ON s.driver_id = d.driver_id
WHERE d.driver_id IS NULL;

-- Impossible delivery dates -> NULL
UPDATE clean.shipments
SET delivered_date = NULL
WHERE delivered_date < ship_date;
GO

/* ========== 5.3 Fix key column types ========== */
ALTER TABLE clean.customers ALTER COLUMN customer_id NVARCHAR(20) NOT NULL;
ALTER TABLE clean.drivers   ALTER COLUMN driver_id   NVARCHAR(20) NOT NULL;
ALTER TABLE clean.vehicles  ALTER COLUMN vehicle_id  NVARCHAR(20) NOT NULL;
ALTER TABLE clean.shipments ALTER COLUMN shipment_id NVARCHAR(20) NOT NULL;
ALTER TABLE clean.shipments ALTER COLUMN customer_id NVARCHAR(20) NOT NULL;
ALTER TABLE clean.shipments ALTER COLUMN driver_id   NVARCHAR(20) NOT NULL;
ALTER TABLE clean.shipments ALTER COLUMN vehicle_id  NVARCHAR(20) NULL;
GO

/* ========== 5.4 Primary Keys ========== */
ALTER TABLE clean.customers ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);
ALTER TABLE clean.drivers   ADD CONSTRAINT PK_drivers   PRIMARY KEY (driver_id);
ALTER TABLE clean.vehicles  ADD CONSTRAINT PK_vehicles  PRIMARY KEY (vehicle_id);
ALTER TABLE clean.shipments ADD CONSTRAINT PK_shipments PRIMARY KEY (shipment_id);
GO

/* ========== 5.5 Foreign Keys ========== */
ALTER TABLE clean.shipments ADD CONSTRAINT FK_shipments_customers
    FOREIGN KEY (customer_id) REFERENCES clean.customers (customer_id);
ALTER TABLE clean.shipments ADD CONSTRAINT FK_shipments_drivers
    FOREIGN KEY (driver_id)   REFERENCES clean.drivers (driver_id);
ALTER TABLE clean.shipments ADD CONSTRAINT FK_shipments_vehicles
    FOREIGN KEY (vehicle_id)  REFERENCES clean.vehicles (vehicle_id);
GO

/* ========== 5.6 Verify ========== */
SELECT name AS fk_name,
       OBJECT_NAME(parent_object_id)     AS from_table,
       OBJECT_NAME(referenced_object_id) AS to_table
FROM sys.foreign_keys;
